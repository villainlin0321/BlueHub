import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_session_provider.dart';
import '../data/user_models.dart';
import '../data/user_providers.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../utils/upload_picker_utils.dart';

import 'package:europepass/shared/ui/test_style.dart';

typedef RealNameImagePicker =
    Future<List<PickedUploadFile>> Function(BuildContext context);
typedef RealNameToastPresenter = Future<void> Function(String message);

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
    extends ConsumerState<JobSeekerRealNameVerificationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idCardController = TextEditingController();

  PickedUploadFile? _frontImage;
  PickedUploadFile? _backImage;
  bool _isSubmitting = false;

  String? _nameError;
  String? _idCardError;
  String? _frontImageError;
  String? _backImageError;

  @override
  /// 初始化输入监听：用户开始修正内容后，及时清理对应的错误提示。
  void initState() {
    super.initState();
    _nameController.addListener(_handleNameChanged);
    _idCardController.addListener(_handleIdCardChanged);
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
    if (_nameError == null || _nameController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _nameError = null;
    });
  }

  /// 身份证号输入变化时清除对应错误，保持表单反馈及时更新。
  void _handleIdCardChanged() {
    if (_idCardError == null || _idCardController.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _idCardError = null;
    });
  }

  /// 统一执行页面内的最小校验，并把错误文案直接展示在对应字段下方。
  bool _validateForm() {
    final String? nextNameError = _nameController.text.trim().isEmpty
        ? '我的.请填写姓名'.tr()
        : null;
    final String? nextIdCardError = _idCardController.text.trim().isEmpty
        ? '我的.请填写身份证号'.tr()
        : null;
    final String? nextFrontImageError =
        _frontImage == null ? '我的.请上传身份证国徽面'.tr() : null;
    final String? nextBackImageError =
        _backImage == null ? '我的.请上传身份证人像面'.tr() : null;

    // 点击提交后统一刷新所有错误状态，确保用户和测试都能看到稳定反馈。
    setState(() {
      _nameError = nextNameError;
      _idCardError = nextIdCardError;
      _frontImageError = nextFrontImageError;
      _backImageError = nextBackImageError;
    });

    return nextNameError == null &&
        nextIdCardError == null &&
        nextFrontImageError == null &&
        nextBackImageError == null;
  }

  /// 提交实名认证信息，并在成功后刷新当前登录用户资料。
  Future<void> _handleSubmit() async {
    if (_isSubmitting || !_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      // 关键提交：只使用当前表单与已上传图片地址组装真实请求体。
      await ref.read(userServiceProvider).realNameVerify(
        request: RealNameVerifyBO(
          realName: _nameController.text.trim(),
          idCardNumber: _idCardController.text.trim(),
          idCardFrontUrl: (_frontImage!.uploadedFileUrl ?? _frontImage!.path)
              .trim(),
          idCardBackUrl: (_backImage!.uploadedFileUrl ?? _backImage!.path)
              .trim(),
        ),
      );
      await ref.read(authSessionProvider.notifier).refreshCurrentUser();
      if (!mounted) {
        return;
      }
      final NavigatorState navigator = Navigator.of(context);
      await _showToast('我的.实名认证提交成功'.tr());
      navigator.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      await _showToast(_resolveSubmitErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 选择身份证图片并更新本地展示状态，默认沿用现有上传工具，也允许测试注入替身。
  Future<void> _pickImage({required bool isFrontSide}) async {
    final RealNameImagePicker picker =
        widget.pickImages ??
        (BuildContext context) =>
            UploadPickerUtils.pickImagesWithSourceSheet(context: context);
    final List<PickedUploadFile> images =
        await picker(context);
    if (!mounted || images.isEmpty) {
      return;
    }

    final PickedUploadFile pickedFile = images.firstWhere(
      (PickedUploadFile file) => file.isImage,
      orElse: () => images.first,
    );
    setState(() {
      if (isFrontSide) {
        _frontImage = pickedFile;
        _frontImageError = null;
      } else {
        _backImage = pickedFile;
        _backImageError = null;
      }
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
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
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFA9C7E6),
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
                  cardKey: const Key('id-card-front-upload'),
                  label: '我的.上传国徽面'.tr(),
                  placeholderAsset: 'assets/images/qualification_id_emblem.png',
                  pickedFile: _frontImage,
                  errorText: _frontImageError,
                  onTap: () => _pickImage(isFrontSide: true),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _UploadColumn(
                  cardKey: const Key('id-card-back-upload'),
                  label: '我的.上传人像面'.tr(),
                  placeholderAsset:
                      'assets/images/qualification_id_portrait.png',
                  pickedFile: _backImage,
                  errorText: _backImageError,
                  onTap: () => _pickImage(isFrontSide: false),
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
      style: TestStyle.regular(
        fontSize: 12,
        color: const Color(0xFF8C8C8C),
      ),
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
  const _UploadIllustration({
    required this.placeholderAsset,
    this.pickedFile,
  });

  final String placeholderAsset;
  final PickedUploadFile? pickedFile;

  @override
  /// 构建上传图像内容，保证无论是否已选图都维持稳定的视觉尺寸。
  Widget build(BuildContext context) {
    if (pickedFile == null) {
      return Image.asset(
        placeholderAsset,
        fit: BoxFit.cover,
      );
    }

    // 关键回退：本地文件不可读时仍展示设计稿示意图，避免卡片空白。
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Image.file(
          File(pickedFile!.path),
          fit: BoxFit.cover,
          errorBuilder: (
            BuildContext context,
            Object error,
            StackTrace? stackTrace,
          ) {
            return Image.asset(
              placeholderAsset,
              fit: BoxFit.cover,
            );
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
              style: TestStyle.regular(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
