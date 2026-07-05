import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:europepass/patrol_test/helpers/job_seeker_real_name_patrol_support.dart';

import '../../auth/application/auth_session_provider.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../data/user_models.dart';
import '../data/user_providers.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/guarded_pop_scope.dart';
import '../../../shared/widgets/unsaved_changes_exit_guard.dart';
import '../../../utils/upload_picker_utils.dart';

import 'package:europepass/shared/ui/test_style.dart';

typedef RealNameImagePicker =
    Future<List<PickedUploadFile>> Function(BuildContext context);
typedef RealNameToastPresenter = Future<void> Function(String message);

/// 记录实名认证页会进入提交请求的关键字段，用于判断是否存在未保存改动。
class _RealNameVerificationSnapshot {
  const _RealNameVerificationSnapshot({
    required this.name,
    required this.idCardNumber,
    required this.emblemImageIdentity,
    required this.portraitImageIdentity,
  });

  final String name;
  final String idCardNumber;
  final String emblemImageIdentity;
  final String portraitImageIdentity;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _RealNameVerificationSnapshot &&
        other.name == name &&
        other.idCardNumber == idCardNumber &&
        other.emblemImageIdentity == emblemImageIdentity &&
        other.portraitImageIdentity == portraitImageIdentity;
  }

  @override
  int get hashCode => Object.hash(
    name,
    idCardNumber,
    emblemImageIdentity,
    portraitImageIdentity,
  );
}

/// 统一归一化实名认证图片身份，确保本地已选图和已上传图都能纳入脏数据判断。
String _buildRealNameImageIdentity(PickedUploadFile? file) {
  if (file == null) {
    return '';
  }
  final String fileId = file.uploadedFileId?.toString() ?? '';
  final String remoteUrl = (file.uploadedFileUrl ?? '').trim();
  final String localPath = file.path.trim();
  final String fileName = file.name.trim();
  return '$fileId|$remoteUrl|$localPath|$fileName';
}

/// 求职者实名认证页：按 Figma 结构展示行式表单、身份证示意图上传区和本地校验。
class JobSeekerRealNameVerificationPage extends ConsumerStatefulWidget {
  const JobSeekerRealNameVerificationPage({
    super.key,
    this.pickImages,
    this.showToast,
  });

  final RealNameImagePicker? pickImages;
  final RealNameToastPresenter? showToast;

  @override
  ConsumerState<JobSeekerRealNameVerificationPage> createState() =>
      _JobSeekerRealNameVerificationPageState();
}

class _JobSeekerRealNameVerificationPageState
    extends ConsumerState<JobSeekerRealNameVerificationPage>
    with GuardedPopScopeMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();

  PickedUploadFile? _emblemImage;
  PickedUploadFile? _portraitImage;
  late _RealNameVerificationSnapshot _initialSnapshot;
  bool _isSubmitting = false;

  String? _nameError;
  String? _idCardError;
  String? _emblemImageError;
  String? _portraitImageError;

  bool get _hasRequiredFieldsFilled =>
      _nameController.text.trim().isNotEmpty &&
      _idCardController.text.trim().isNotEmpty &&
      _emblemImage != null &&
      _portraitImage != null;

  bool get _canSubmit => !_isSubmitting && _hasRequiredFieldsFilled;

  @override
  /// 初始化输入监听：用户开始修正内容后，及时清理对应的错误提示。
  void initState() {
    super.initState();
    _nameController.addListener(_handleNameChanged);
    _idCardController.addListener(_handleIdCardChanged);
    _initialSnapshot = _buildCurrentSnapshot();
  }

  @override
  /// 释放控制器与监听，避免页面销毁后残留无效引用。
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _idCardController.removeListener(_handleIdCardChanged);
    _nameController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  /// 姓名输入变化时清除对应错误，避免用户修正后仍显示旧提示。
  void _handleNameChanged() {
    setState(() {
      if (_nameController.text.trim().isNotEmpty) {
        _nameError = null;
      }
    });
  }

  /// 身份证号输入变化时清除对应错误，保持表单反馈及时更新。
  void _handleIdCardChanged() {
    setState(() {
      if (_idCardController.text.trim().isNotEmpty) {
        _idCardError = null;
      }
    });
  }

  /// 汇总会影响实名认证提交结果的字段，作为页面未保存判断的统一基线。
  _RealNameVerificationSnapshot _buildCurrentSnapshot() {
    return _RealNameVerificationSnapshot(
      name: _nameController.text.trim(),
      idCardNumber: _idCardController.text.trim(),
      emblemImageIdentity: _buildRealNameImageIdentity(_emblemImage),
      portraitImageIdentity: _buildRealNameImageIdentity(_portraitImage),
    );
  }

  /// 统一处理头部返回和系统返回；存在未保存改动时先弹出二次确认。
  Future<void> _handleAttemptLeave() async {
    final bool hasUnsavedChanges = _buildCurrentSnapshot() != _initialSnapshot;
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: hasUnsavedChanges,
    );
    if (!mounted || !canLeave) {
      return;
    }
    scheduleDirectPop();
  }

  /// 统一执行页面内的最小校验，并把错误文案直接展示在对应字段下方。
  bool _validateForm() {
    final String? nextNameError = _nameController.text.trim().isEmpty
        ? '我的.请填写姓名'.tr()
        : null;
    final String? nextIdCardError = _idCardController.text.trim().isEmpty
        ? '我的.请填写身份证号'.tr()
        : null;
    final String? nextEmblemImageError = _emblemImage == null
        ? '我的.请上传身份证国徽面'.tr()
        : null;
    final String? nextPortraitImageError = _portraitImage == null
        ? '我的.请上传身份证人像面'.tr()
        : null;

    // 点击提交后统一刷新所有错误状态，确保用户和测试都能看到稳定反馈。
    setState(() {
      _nameError = nextNameError;
      _idCardError = nextIdCardError;
      _emblemImageError = nextEmblemImageError;
      _portraitImageError = nextPortraitImageError;
    });

    return nextNameError == null &&
        nextIdCardError == null &&
        nextEmblemImageError == null &&
        nextPortraitImageError == null;
  }

  /// 提交实名认证信息，并在成功后刷新当前登录用户资料。
  Future<void> _handleSubmit() async {
    if (_isSubmitting || !_validateForm()) {
      return;
    }

    bool didShowSubmittingLoading = false;
    setState(() {
      _isSubmitting = true;
    });
    try {
      await EasyLoading.show(maskType: EasyLoadingMaskType.black);
      didShowSubmittingLoading = true;
      final PickedUploadFile uploadedEmblemImage =
          await _uploadIdCardImageIfNeeded(isEmblemSide: true);
      final PickedUploadFile uploadedPortraitImage =
          await _uploadIdCardImageIfNeeded(isEmblemSide: false);

      // 关键提交：沿用现有接口契约，不改字段名，只修正页面语义与 front/back 的映射关系。
      await ref
          .read(userServiceProvider)
          .realNameVerify(
            request: _buildRealNameVerifyRequest(
              uploadedEmblemImage: uploadedEmblemImage,
              uploadedPortraitImage: uploadedPortraitImage,
            ),
          );
      final authSession = ref.read(authSessionProvider);
      final bool refreshed = await ref
          .read(authSessionProvider.notifier)
          .refreshCurrentUser(
            // 刷新失败时保留当前登录态，避免实名成功后被误清会话。
            fallbackUser: authSession.user,
            preferredNeedSelectRole: authSession.needSelectRole,
          );
      if (!mounted) {
        return;
      }
      if (didShowSubmittingLoading) {
        await EasyLoading.dismiss();
        didShowSubmittingLoading = false;
      }
      await _handleSubmitSuccess(refreshed: refreshed);
    } catch (error) {
      if (didShowSubmittingLoading) {
        await EasyLoading.dismiss();
        didShowSubmittingLoading = false;
      }
      if (!mounted) {
        return;
      }
      await _showToast(_resolveSubmitErrorMessage(error));
    } finally {
      if (didShowSubmittingLoading && EasyLoading.isShow) {
        await EasyLoading.dismiss();
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 确保身份证图片在实名提交前已经上传到文件服务，并把远端地址回写到当前页面状态。
  Future<PickedUploadFile> _uploadIdCardImageIfNeeded({
    required bool isEmblemSide,
  }) async {
    final PickedUploadFile targetFile = isEmblemSide
        ? _emblemImage!
        : _portraitImage!;
    final String remoteUrl = (targetFile.uploadedFileUrl ?? '').trim();
    if (remoteUrl.isNotEmpty) {
      return targetFile;
    }

    final FilePresignVO uploaded = await ref
        .read(fileServiceProvider)
        .uploadFile(
          path: targetFile.path,
          scene: FileScene.idCard,
          errorMessage: '上传.文件上传失败'.tr(),
        );
    final PickedUploadFile uploadedFile = targetFile.copyWith(
      state: UploadItemState.success,
      progress: 1,
      errorMessage: null,
      uploadedFileId: uploaded.fileId,
      uploadedFileUrl: uploaded.fileUrl,
    );
    if (mounted) {
      setState(() {
        if (isEmblemSide) {
          _emblemImage = uploadedFile;
        } else {
          _portraitImage = uploadedFile;
        }
      });
    }
    return uploadedFile;
  }

  Future<void> _handleImagePickTap({required bool isEmblemSide}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await _pickImage(isEmblemSide: isEmblemSide);
  }

  /// 选择身份证图片并更新本地展示状态，默认沿用现有上传工具，也允许测试注入替身。
  Future<void> _pickImage({required bool isEmblemSide}) async {
    final JobSeekerRealNamePatrolSupport? patrolSupport = ref.read(
      jobSeekerRealNamePatrolSupportProvider,
    );
    final RealNameImagePicker picker =
        widget.pickImages ??
        (BuildContext context) {
          if (patrolSupport != null) {
            // 关键测试缝：Patrol 可直接回填测试图片，避免 iOS 原生相册控件影响自动化稳定性。
            return patrolSupport.pickImages(
              context,
              isEmblemSide: isEmblemSide,
            );
          }
          return UploadPickerUtils.pickImagesWithSourceSheet(context: context);
        };
    final List<PickedUploadFile> images = await picker(context);
    if (!mounted || images.isEmpty) {
      return;
    }

    final PickedUploadFile pickedFile = images.firstWhere(
      (PickedUploadFile file) => file.isImage,
      orElse: () => images.first,
    );
    setState(() {
      if (isEmblemSide) {
        _emblemImage = pickedFile;
        _emblemImageError = null;
      } else {
        _portraitImage = pickedFile;
        _portraitImageError = null;
      }
    });
  }

  /// 按现有后端字段契约组装实名请求，明确 front=人像面、back=国徽面。
  RealNameVerifyBO _buildRealNameVerifyRequest({
    required PickedUploadFile uploadedEmblemImage,
    required PickedUploadFile uploadedPortraitImage,
  }) {
    return RealNameVerifyBO(
      realName: _nameController.text.trim(),
      idCardNumber: _idCardController.text.trim(),
      idCardFrontUrl: uploadedPortraitImage.uploadedFileUrl!.trim(),
      idCardBackUrl: uploadedEmblemImage.uploadedFileUrl!.trim(),
    );
  }

  /// 在实名接口成功后统一处理反馈；资料刷新失败时也保持成功返回语义。
  Future<void> _handleSubmitSuccess({required bool refreshed}) async {
    final String message = refreshed
        ? '我的.实名认证提交成功'.tr()
        : '我的.实名认证提交成功但资料刷新失败'.tr();
    await _showToast(message);
    if (!mounted) {
      return;
    }
    // 提交成功后允许本次返回直接放行，避免被未保存拦截误伤。
    scheduleDirectPop(result: true);
  }

  /// 统一分发页面提示，生产默认走全局 Toast，测试可注入空实现避免动画干扰。
  Future<void> _showToast(String message) {
    final RealNameToastPresenter presenter = widget.showToast ?? AppToast.show;
    return presenter(message);
  }

  /// 统一提取实名提交失败提示，优先展示接口返回文案。
  String _resolveSubmitErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '我的.实名认证提交失败'.tr();
  }

  @override
  /// 构建实名认证页，按截图分为顶部标题、单张表单卡片、底部说明和固定提交区。
  Widget build(BuildContext context) {
    return buildGuardedPopScope(
      onInterceptPop: _handleAttemptLeave,
      child: TapBlankToDismissKeyboard(
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              // 统一走页面级返回判断，避免头部按钮绕过未保存拦截。
              onPressed: _handleAttemptLeave,
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: Color(0xE6000000),
              ),
            ),
            title: Text(
              '我的.实名认证'.tr(),
              style: TestStyle.medium(
                fontSize: 17,
                color: const Color(0xE6000000),
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildFormCard(),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildInstructionText(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  key: const Key('real-name-submit-button'),
                  onPressed: _canSubmit ? _handleSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _canSubmit
                        ? const Color(0xFF096DD9)
                        : const Color(0xFFA9C7E6),
                    disabledBackgroundColor: const Color(0xFFA9C7E6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '我的.实名认证提交'.tr(),
                    style: TestStyle.pingFangRegular(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建白色表单卡片内容，集中管理输入区与身份证上传区，避免主构建函数过长。
  Widget _buildFormCard() {
    return _RealNameFormCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _InlineInputRow(
            label: '我的.实名认证姓名'.tr(),
            controller: _nameController,
            fieldKey: const Key('real-name-input'),
            errorText: _nameError,
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFF0F0F0)),
          _InlineInputRow(
            label: '我的.实名认证身份证号'.tr(),
            controller: _idCardController,
            fieldKey: const Key('id-card-input'),
            errorText: _idCardError,
          ),
          const SizedBox(height: 24),
          Text(
            '我的.身份证验证'.tr(),
            style: TestStyle.regular(
              fontSize: 16,
              color: const Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '我的.请上传本人的身份证照片'.tr(),
            style: TestStyle.regular(
              fontSize: 12,
              color: const Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _UploadColumn(
                  cardKey: const Key('id-card-emblem-upload'),
                  label: '我的.上传国徽面'.tr(),
                  placeholderAsset: 'assets/images/qualification_id_emblem.png',
                  pickedFile: _emblemImage,
                  errorText: _emblemImageError,
                  onTap: () => _handleImagePickTap(isEmblemSide: true),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _UploadColumn(
                  cardKey: const Key('id-card-portrait-upload'),
                  label: '我的.上传人像面'.tr(),
                  placeholderAsset:
                      'assets/images/qualification_id_portrait.png',
                  pickedFile: _portraitImage,
                  errorText: _portraitImageError,
                  onTap: () => _handleImagePickTap(isEmblemSide: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建底部说明文案，大屏时贴近固定按钮区，小屏时随滚动内容一起向下展开。
  Widget _buildInstructionText() {
    return Text(
      '我的.实名认证说明文案'.tr(),
      style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
    );
  }
}

/// 单张白色表单卡片：承载行式输入与身份证验证区，尽量贴近 Figma 白卡层级。
class _RealNameFormCard extends StatelessWidget {
  const _RealNameFormCard({required this.child});

  final Widget child;

  @override
  /// 构建表单白卡，统一控制圆角、内边距和背景色。
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      child: child,
    );
  }
}

/// 行式输入项：左侧标题、右侧轻量输入框，下方展示字段级错误文案。
class _InlineInputRow extends StatelessWidget {
  const _InlineInputRow({
    required this.label,
    required this.controller,
    required this.fieldKey,
    this.errorText,
  });

  final String label;
  final TextEditingController controller;
  final Key fieldKey;
  final String? errorText;

  @override
  /// 构建 Figma 风格的单行输入区域，而不是大面积块状输入框。
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 52,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 88,
                child: Text(
                  label,
                  style: TestStyle.regular(
                    fontSize: 16,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  textAlign: TextAlign.left,
                  style: TestStyle.regular(
                    fontSize: 16,
                    color: const Color(0xFF262626),
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: '通用.请输入'.tr(),
                    hintStyle: TestStyle.regular(
                      fontSize: 16,
                      color: const Color(0xFFBFBFBF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              errorText!,
              style: TestStyle.regular(
                fontSize: 12,
                color: const Color(0xFFFF4D4F),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 单个身份证上传列：顶部为示意图或本地预览，底部是标签与错误信息。
class _UploadColumn extends StatelessWidget {
  const _UploadColumn({
    required this.cardKey,
    required this.label,
    required this.placeholderAsset,
    required this.onTap,
    this.pickedFile,
    this.errorText,
  });

  final Key cardKey;
  final String label;
  final String placeholderAsset;
  final VoidCallback onTap;
  final PickedUploadFile? pickedFile;
  final String? errorText;

  @override
  /// 构建上传列，空态展示设计稿示意图，选图后展示本地预览。
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        GestureDetector(
          key: cardKey,
          onTap: onTap,
          child: SizedBox(
            height: 116,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _UploadIllustration(
                placeholderAsset: placeholderAsset,
                pickedFile: pickedFile,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          label,
          style: TestStyle.regular(
            fontSize: 12,
            color: const Color(0xFF262626),
          ),
        ),
        if (errorText != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(
            errorText!,
            textAlign: TextAlign.center,
            style: TestStyle.regular(
              fontSize: 12,
              color: const Color(0xFFFF4D4F),
            ),
          ),
        ],
      ],
    );
  }
}

/// 上传示意图区域：优先展示用户选择的本地图片，失败时回退到设计稿示意图。
class _UploadIllustration extends StatelessWidget {
  const _UploadIllustration({required this.placeholderAsset, this.pickedFile});

  final String placeholderAsset;
  final PickedUploadFile? pickedFile;

  @override
  /// 构建上传图像内容，保证无论是否已选图都维持稳定的视觉尺寸。
  Widget build(BuildContext context) {
    if (pickedFile == null) {
      return Image.asset(placeholderAsset, fit: BoxFit.cover);
    }

    // 关键回退：本地文件不可读时仍展示设计稿示意图，避免卡片空白。
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.file(
          File(pickedFile!.path),
          fit: BoxFit.cover,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return Image.asset(placeholderAsset, fit: BoxFit.cover);
              },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            color: Colors.black.withValues(alpha: 0.45),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Text(
              pickedFile!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TestStyle.regular(fontSize: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
