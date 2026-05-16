import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../auth/application/auth_user.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../../me/data/user_models.dart';
import '../../me/data/user_providers.dart';
import 'current_user_view_data.dart';

/// 我的信息页：展示当前登录用户的基础资料，并支持基础信息编辑。
class MyInfoPage extends ConsumerStatefulWidget {
  const MyInfoPage({super.key});

  @override
  ConsumerState<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends ConsumerState<MyInfoPage> {
  static const String _avatarAsset = 'assets/images/mou4gf12-gby6i3c.png';
  static const List<SelectableSheetOption<String>> _genderOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: 'male', label: '男'),
        SelectableSheetOption<String>(value: 'female', label: '女'),
        SelectableSheetOption<String>(value: 'unknown', label: '未填写'),
      ];

  bool _isSubmitting = false;

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
                            label: '头像',
                            avatarUrl: userViewData.avatarUrl,
                            fallbackAssetPath: _avatarAsset,
                            onTap: _handleAvatarTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            label: '出生日期',
                            value: userViewData.birthdayText,
                            onTap: _handleBirthdayTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            label: '性别',
                            value: userViewData.genderText,
                            onTap: _handleGenderTap,
                          ),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFF0F0F0),
                          ),
                          _InfoValueRow(
                            label: '手机号',
                            value: userViewData.maskedPhone,
                            showChevron: false,
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
              errorMessage: '打开相机失败，请稍后重试',
            );
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickAndUploadAvatar(
              picker: UploadPickerUtils.pickFromGallery,
              errorMessage: '打开相册失败，请稍后重试',
            );
          },
        );
      },
    );
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
      successMessage: '出生日期已更新',
    );
  }

  /// 打开性别单选面板，并将选择结果同步到服务端。
  Future<void> _handleGenderTap() async {
    final AuthUser? currentUser = ref.read(authSessionProvider).user;
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '选择性别',
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
      successMessage: '性别已更新',
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

      await _executeProfileAction(
        action: () async {
          final int avatarId = await _uploadAvatar(selectedFile.path);
          await ref
              .read(userServiceProvider)
              .updateMe(request: UpdateUserBO(avatarId: avatarId));
        },
        successMessage: '头像已更新',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
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
          errorMessage: '头像上传失败，请稍后重试',
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
    return '保存失败，请稍后重试';
  }

  /// 统一通过页面级 Snackbar 提示保存结果与异常信息。
  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          const Text(
            '我的信息',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
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
    required this.fallbackAssetPath,
    this.onTap,
  });

  final String label;
  final String avatarUrl;
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
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
            const Spacer(),
            _MyInfoAvatar(
              avatarUrl: avatarUrl,
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
    required this.label,
    required this.value,
    this.onTap,
    this.showChevron = true,
  });

  final String label;
  final String value;
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
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 16,
                height: 22 / 16,
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
    required this.fallbackAssetPath,
    required this.size,
  });

  final String avatarUrl;
  final String fallbackAssetPath;
  final double size;

  @override
  /// 构建圆形头像，并兼容加载中与加载失败场景。
  Widget build(BuildContext context) {
    final Widget fallback = ClipOval(
      child: Image.asset(
        fallbackAssetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
    if (avatarUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? event) {
              if (event == null) {
                return child;
              }
              return fallback;
            },
      ),
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
            const Text(
              '选择头像',
              style: TextStyle(
                color: Color(0xFF262626),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
            const SizedBox(height: 12),
            _BottomSheetActionTile(label: '拍照', onTap: onCameraTap),
            _BottomSheetActionTile(label: '从相册选择', onTap: onGalleryTap),
            const SizedBox(height: 8),
            _BottomSheetActionTile(label: '取消', onTap: onClose),
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
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
        ),
      ),
    );
  }
}
