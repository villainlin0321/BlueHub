import 'dart:io';
import '../../../shared/widgets/app_toast.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../auth/application/auth_user.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../../me/data/user_models.dart';
import '../../me/data/user_providers.dart';
import 'current_user_view_data.dart';
import 'my_info_contact_edit_page.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 我的信息页：展示当前登录用户的基础资料，并支持基础信息编辑。
class MyInfoPage extends ConsumerStatefulWidget {
  const MyInfoPage({super.key});

  @override
  ConsumerState<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends ConsumerState<MyInfoPage> {
  static const String _avatarAsset = 'assets/images/mou4gf12-gby6i3c.png';

  bool _isSubmitting = false;
  String? _localAvatarPreviewPath;

  /// 返回性别选择项，运行时读取国际化文案。
  List<SelectableSheetOption<String>> get _genderOptions =>
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: 'male', label: '我的.男'.tr()),
        SelectableSheetOption<String>(value: 'female', label: '我的.女'.tr()),
        SelectableSheetOption<String>(value: 'unknown', label: '我的.未完善'.tr()),
      ];

  @override
  /// 构建“我的信息”页面，并根据当前登录态刷新展示内容。
  Widget build(BuildContext context) {
    final AuthUser? currentUser = ref.watch(authSessionProvider).user;
    final CurrentUserViewData userViewData = CurrentUserViewData.fromAuthUser(
      currentUser,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _MyInfoHeader(onBackTap: context.pop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: <Widget>[
                          _InfoAvatarRow(
                            label: '我的.头像'.tr(),
                            avatarUrl: userViewData.avatarUrl,
                            localAvatarPath: _localAvatarPreviewPath,
                            fallbackAssetPath: _avatarAsset,
                            onTap: _handleAvatarTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            key: const Key('my-info-nickname-row'),
                            label: '我的.昵称'.tr(),
                            value: userViewData.nickname,
                            valueColor: const Color(0xFF262626),
                            onTap: _handleNicknameTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            key: const Key('my-info-real-name-row'),
                            label: '我的.实名认证'.tr(),
                            value: userViewData.realNameText,
                            onTap: _handleRealNameTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            label: '我的.出生日期'.tr(),
                            value: userViewData.birthdayText,
                            onTap: _handleBirthdayTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            label: '我的.性别'.tr(),
                            value: userViewData.genderText,
                            onTap: _handleGenderTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            label: '我的.手机号'.tr(),
                            value: userViewData.maskedPhone,
                            onTap: _handlePhoneTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            key: const Key('my-info-email-row'),
                            label: '我的.邮箱'.tr(),
                            value: userViewData.emailText,
                            onTap: _handleEmailTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x33000000),
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 打开头像来源面板，并让用户选择拍照或相册。
  Future<void> _handleAvatarTap() async {
    if (_isSubmitting) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (BuildContext sheetContext) {
        return _ImageSourceBottomSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onCameraTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickAndUploadAvatar(
              picker: UploadPickerUtils.pickFromCamera,
              errorMessage: '我的.打开相机失败'.tr(),
            );
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickAndUploadAvatar(
              picker: UploadPickerUtils.pickFromGallery,
              errorMessage: '我的.打开相册失败'.tr(),
            );
          },
        );
      },
    );
  }

  /// 弹出昵称编辑框，并在确认后真实更新当前用户昵称。
  Future<void> _handleNicknameTap() async {
    if (_isSubmitting) {
      return;
    }

    final String currentNickname =
        ref.read(authSessionProvider).user?.nickname.trim() ?? '';
    final String? nextNickname = await showAppDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (BuildContext dialogContext) {
        return _EditNicknameDialog(initialNickname: currentNickname);
      },
    );
    if (!mounted || nextNickname == null || nextNickname == currentNickname) {
      return;
    }

    await _executeProfileAction(
      action: () => ref
          .read(userServiceProvider)
          .updateMe(request: UpdateUserBO(nickname: nextNickname)),
      successMessage: '我的.昵称已更新'.tr(),
    );
  }

  /// 进入实名认证页面，沿用既有路由。
  void _handleRealNameTap() {
    context.push(RoutePaths.jobSeekerRealNameVerification);
  }

  /// 打开生日选择器，并把结果回写到用户资料。
  Future<void> _handleBirthdayTap() async {
    final AuthUser? currentUser = ref.read(authSessionProvider).user;
    final DateTime now = DateTime.now();
    final DateTime initialDate =
        _parseBirthday(currentUser?.birthday) ??
        DateTime(now.year - 20, now.month, now.day);
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
    );
    if (pickedDate == null) {
      return;
    }

    await _executeProfileAction(
      action: () => ref
          .read(userServiceProvider)
          .updateMe(
            request: UpdateUserBO(birthday: _formatBirthdayForApi(pickedDate)),
          ),
      successMessage: '我的.出生日期已更新'.tr(),
    );
  }

  /// 打开性别单选面板，并将选择结果同步到服务端。
  Future<void> _handleGenderTap() async {
    final AuthUser? currentUser = ref.read(authSessionProvider).user;
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '我的.选择性别'.tr(),
      options: _genderOptions,
      initialSelectedValues: <String>[
        _normalizeGenderValue(currentUser?.gender),
      ],
      multiple: false,
    );
    if (result == null || result.isEmpty) {
      return;
    }

    await _executeProfileAction(
      action: () => ref
          .read(userServiceProvider)
          .updateMe(request: UpdateUserBO(gender: result.first)),
      successMessage: '我的.性别已更新'.tr(),
    );
  }

  /// 打开手机号编辑弹窗，当前版本先承载输入与确认交互。
  Future<void> _handlePhoneTap() async {
    context.push(
      RoutePaths.myInfoContactEdit,
      extra: const MyInfoContactEditPageArgs.phone(),
    );
  }

  /// 进入邮箱编辑页，当前复用统一的联系方式编辑页面。
  Future<void> _handleEmailTap() async {
    context.push(
      RoutePaths.myInfoContactEdit,
      extra: const MyInfoContactEditPageArgs.email(),
    );
  }

  /// 选择头像后完成预签名上传，并把返回的文件 ID 回写到资料接口。
  Future<void> _pickAndUploadAvatar({
    required Future<List<PickedUploadFile>> Function() picker,
    required String errorMessage,
  }) async {
    try {
      final List<PickedUploadFile> files = await picker();
      if (!mounted || files.isEmpty) {
        return;
      }

      PickedUploadFile selectedFile = files.first;
      for (final PickedUploadFile item in files) {
        if (item.isImage) {
          selectedFile = item;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _localAvatarPreviewPath = selectedFile.path;
        });
      }

      await _executeProfileAction(
        action: () async {
          final int avatarId = await _uploadAvatar(selectedFile.path);
          await ref
              .read(userServiceProvider)
              .updateMe(request: UpdateUserBO(avatarId: avatarId));
        },
        successMessage: '我的.头像已更新'.tr(),
      );
      if (mounted) {
        setState(() {
          _localAvatarPreviewPath = null;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localAvatarPreviewPath = null;
      });
      _showMessage(errorMessage);
    }
  }

  /// 执行资料更新操作，并在成功后统一刷新当前登录态。
  Future<void> _executeProfileAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await action();
      final authSession = ref.read(authSessionProvider);
      await ref
          .read(authSessionProvider.notifier)
          .refreshCurrentUser(
            fallbackUser: authSession.user,
            preferredNeedSelectRole: authSession.needSelectRole,
          );
      if (!mounted) {
        return;
      }
      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 根据文件接口完成头像上传，返回可用于 `updateMe` 的文件 ID。
  Future<int> _uploadAvatar(String path) async {
    final FilePresignVO presign = await ref
        .read(fileServiceProvider)
        .uploadFile(
          path: path,
          scene: FileScene.avatar,
          errorMessage: '我的.头像上传失败'.tr(),
        );
    return presign.fileId;
  }

  /// 将服务端生日值解析为可用于日期选择器的 `DateTime`。
  DateTime? _parseBirthday(String? birthday) {
    final String value = (birthday ?? '').trim();
    if (value.isEmpty) {
      return null;
    }

    final List<String> parts = value
        .replaceAll('.', '-')
        .replaceAll('/', '-')
        .split('-');
    if (parts.length < 3) {
      return null;
    }

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  /// 将日期选择结果格式化为后端要求的 `YYYY-MM-DD`。
  String _formatBirthdayForApi(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  /// 归一化服务端性别值，避免大小写或历史值影响默认选中态。
  String _normalizeGenderValue(String? value) {
    switch ((value ?? '').trim().toLowerCase()) {
      case 'male':
      case 'man':
      case 'm':
      case '1':
      case '男':
        return 'male';
      case 'female':
      case 'woman':
      case 'f':
      case '0':
      case '女':
        return 'female';
      default:
        return 'unknown';
    }
  }

  /// 把接口异常转换成可直接展示给用户的提示文案。
  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '我的.保存失败'.tr();
  }

  /// 统一通过页面级 Snackbar 提示保存结果与异常信息。
  void _showMessage(String message) {
    AppToast.show(message);
  }
}

class _MyInfoHeader extends StatelessWidget {
  const _MyInfoHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  /// 构建顶部返回栏，保持与设计稿一致的标题与交互位置。
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
            ),
          ),
          Text(
            '我的.我的信息'.tr(),
            style: TestStyle.pingFangMedium(
              fontSize: 17,
              color: Color(0xFF262626),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoAvatarRow extends StatelessWidget {
  const _InfoAvatarRow({
    required this.label,
    required this.avatarUrl,
    required this.localAvatarPath,
    required this.fallbackAssetPath,
    this.onTap,
  });

  final String label;
  final String avatarUrl;
  final String? localAvatarPath;
  final String fallbackAssetPath;
  final VoidCallback? onTap;

  @override
  /// 构建头像行，优先展示服务端头像，失败时回退到本地占位图。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: <Widget>[
            Text(
              label,
              style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
            ),
            const Spacer(),
            _MyInfoAvatar(
              avatarUrl: avatarUrl,
              localAvatarPath: localAvatarPath,
              fallbackAssetPath: fallbackAssetPath,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoValueRow extends StatelessWidget {
  const _InfoValueRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF8C8C8C),
    this.onTap,
    this.showChevron = true,
  });

  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  /// 构建基础资料行，支持可点击编辑和只读展示两种状态。
  Widget build(BuildContext context) {
    final Widget trailing = showChevron
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Color(0xFFBFBFBF)),
            ],
          )
        : const SizedBox.shrink();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: <Widget>[
            Text(
              label,
              style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TestStyle.regular(fontSize: 16, color: valueColor),
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _MyInfoAvatar extends StatelessWidget {
  const _MyInfoAvatar({
    required this.avatarUrl,
    required this.localAvatarPath,
    required this.fallbackAssetPath,
    required this.size,
  });

  final String avatarUrl;
  final String? localAvatarPath;
  final String fallbackAssetPath;
  final double size;

  @override
  /// 构建圆形头像，并兼容加载中与加载失败场景。
  Widget build(BuildContext context) {
    final String resolvedLocalAvatarPath = localAvatarPath?.trim() ?? '';
    if (resolvedLocalAvatarPath.isNotEmpty) {
      return ClipOval(
        child: Image.file(
          File(resolvedLocalAvatarPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return AppUserAvatar(
              imageUrl: avatarUrl,
              size: size,
              placeholderAssetPath: fallbackAssetPath,
            );
          },
        ),
      );
    }

    return AppUserAvatar(
      imageUrl: avatarUrl,
      size: size,
      placeholderAssetPath: fallbackAssetPath,
    );
  }
}

class _ImageSourceBottomSheet extends StatelessWidget {
  const _ImageSourceBottomSheet({
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
  });

  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;

  @override
  /// 构建头像来源选择面板，统一承载拍照与相册入口。
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '我的.选择头像'.tr(),
              style: TestStyle.pingFangMedium(
                fontSize: 17,
                color: Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 12),
            _BottomSheetActionTile(label: '我的.拍照'.tr(), onTap: onCameraTap),
            _BottomSheetActionTile(label: '我的.从相册选择'.tr(), onTap: onGalleryTap),
            const SizedBox(height: 8),
            _BottomSheetActionTile(label: '通用.取消'.tr(), onTap: onClose),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetActionTile extends StatelessWidget {
  const _BottomSheetActionTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  /// 构建底部动作项，统一资料编辑弹层的点击样式。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 52,
        child: Center(
          child: Text(
            label,
            style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
          ),
        ),
      ),
    );
  }
}

class _EditNicknameDialog extends StatefulWidget {
  const _EditNicknameDialog({required this.initialNickname});

  final String initialNickname;

  @override
  State<_EditNicknameDialog> createState() => _EditNicknameDialogState();
}

class _EditNicknameDialogState extends State<_EditNicknameDialog> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNickname);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final String nickname = _controller.text.trim();
    if (nickname.isEmpty) {
      setState(() {
        _errorText = '我的.请输入昵称'.tr();
      });
      return;
    }
    if (nickname.length > 20) {
      setState(() {
        _errorText = '我的.昵称长度限制'.tr();
      });
      return;
    }
    Navigator.of(context).pop(nickname);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: '我的.修改昵称'.tr(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            '我的.请输入昵称'.tr(),
            style: TestStyle.pingFangRegular(
              fontSize: 14,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('my-info-nickname-input'),
            controller: _controller,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            inputFormatters: <TextInputFormatter>[
              LengthLimitingTextInputFormatter(20),
            ],
            cursorColor: AppColors.brand,
            onChanged: (_) {
              if (_errorText == null) {
                return;
              }
              setState(() {
                _errorText = null;
              });
            },
            onSubmitted: (_) => _handleConfirm(),
            decoration: InputDecoration(
              hintText: '我的.请输入昵称'.tr(),
              hintStyle: TestStyle.pingFangRegular(
                fontSize: 15,
                color: Color(0xFFBFBFBF),
              ),
              filled: true,
              fillColor: const Color(0xFFF5F7FA),
              errorText: _errorText,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.brand),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.danger),
              ),
            ),
          ),
        ],
      ),
      actions: <AppDialogAction>[
        AppDialogAction.secondary(
          label: '通用.取消'.tr(),
          onPressed: () => Navigator.of(context).pop(),
        ),
        AppDialogAction.primary(label: '通用.确定'.tr(), onPressed: _handleConfirm),
      ],
    );
  }
}
