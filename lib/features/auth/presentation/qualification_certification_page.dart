import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../application/qualification_upload_helper.dart';
import '../../../utils/upload_picker_utils.dart';
import 'qualification_certification_flow.dart';
import 'widgets/qualification_progress_stepper.dart';

class QualificationCertificationPage extends ConsumerStatefulWidget {
  const QualificationCertificationPage({
    super.key,
    required this.args,
  });

  final QualificationCertificationPageArgs args;

  @override
  ConsumerState<QualificationCertificationPage> createState() =>
      _QualificationCertificationPageState();
}

class _QualificationCertificationPageState
    extends ConsumerState<QualificationCertificationPage> {
  static const List<String> _steps = <String>[
    '基本信息',
    '资质证明',
    '服务信息',
  ];

  final TextEditingController _serviceProviderCompanyNameController =
      TextEditingController();
  final TextEditingController _creditCodeController = TextEditingController();
  final TextEditingController _legalPersonController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyManagerNameController =
      TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();

  PickedUploadFile? _idCardEmblemImage;
  PickedUploadFile? _idCardPortraitImage;
  String? _selectedCompanyCountry;
  bool _isUploadingEmblem = false;
  bool _isUploadingPortrait = false;

  QualificationCertificationRole get _role => widget.args.role;
  bool get _isCompany => _role == QualificationCertificationRole.company;
  QualificationCertificationDraft get _draft => widget.args.draft;

  bool get _isCompanyNextEnabled {
    return _companyNameController.text.trim().isNotEmpty &&
        (_selectedCompanyCountry?.trim().isNotEmpty ?? false) &&
        _companyManagerNameController.text.trim().isNotEmpty &&
        _companyPhoneController.text.trim().isNotEmpty &&
        _isValidEmail(_companyEmailController.text);
  }

  @override
  void initState() {
    super.initState();
    _serviceProviderCompanyNameController.text = _draft.serviceProviderCompanyName;
    _creditCodeController.text = _draft.unifiedCreditCode;
    _legalPersonController.text = _draft.legalPerson;
    _contactPersonController.text = _draft.contactPerson;
    _phoneController.text = _draft.contactPhone;
    _emailController.text = _draft.contactEmail;
    _websiteController.text = _draft.website;
    _companyNameController.text = _draft.companyName;
    _companyManagerNameController.text = _draft.companyManagerName;
    _companyPhoneController.text = _draft.companyPhone;
    _companyEmailController.text = _draft.companyEmail;
    _selectedCompanyCountry = _draft.companyCountryLabel.isEmpty
        ? null
        : _draft.companyCountryLabel;
    if (_draft.idCardEmblemDoc != null) {
      _idCardEmblemImage = PickedUploadFile(
        id: 'qualification-id-emblem',
        path: _draft.idCardEmblemDoc!.localPath,
        name: _draft.idCardEmblemDoc!.docName,
        isImage: true,
        sizeLabel: '',
        sourceType: UploadSourceType.gallery,
        state: UploadItemState.success,
      );
    }
    if (_draft.idCardPortraitDoc != null) {
      _idCardPortraitImage = PickedUploadFile(
        id: 'qualification-id-portrait',
        path: _draft.idCardPortraitDoc!.localPath,
        name: _draft.idCardPortraitDoc!.docName,
        isImage: true,
        sizeLabel: '',
        sourceType: UploadSourceType.gallery,
        state: UploadItemState.success,
      );
    }
    _companyNameController.addListener(_handleCompanyFormChanged);
    _companyManagerNameController.addListener(_handleCompanyFormChanged);
    _companyPhoneController.addListener(_handleCompanyFormChanged);
    _companyEmailController.addListener(_handleCompanyFormChanged);
  }

  @override
  void dispose() {
    _serviceProviderCompanyNameController.dispose();
    _creditCodeController.dispose();
    _legalPersonController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _companyNameController.dispose();
    _companyManagerNameController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  void _handleCompanyFormChanged() {
    if (_isCompany && mounted) {
      setState(() {});
    }
  }

  bool _isValidEmail(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  Future<void> _pickIdentityCardImage({
    required bool isEmblemSide,
  }) async {
    final List<PickedUploadFile> files =
        await UploadPickerUtils.pickImagesWithSourceSheet(
          context: context,
          title: '选择图片',
        );
    if (!mounted || files.isEmpty) {
      return;
    }

    final PickedUploadFile pickedFile = files.firstWhere(
      (PickedUploadFile file) => file.isImage,
      orElse: () => files.first,
    );
    setState(() {
      if (isEmblemSide) {
        _isUploadingEmblem = true;
      } else {
        _isUploadingPortrait = true;
      }
    });
    try {
      final UploadedQualificationDoc uploadedDoc =
          await QualificationUploadHelper.uploadQualificationImage(
            ref: ref,
            file: pickedFile,
            docType: QualificationDocType.idCard,
            docName: isEmblemSide ? '法人身份证国徽面' : '法人身份证人像面',
          );
      if (!mounted) {
        return;
      }
      setState(() {
        if (isEmblemSide) {
          _idCardEmblemImage = pickedFile;
          _draft.idCardEmblemDoc = uploadedDoc;
        } else {
          _idCardPortraitImage = pickedFile;
          _draft.idCardPortraitDoc = uploadedDoc;
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    } finally {
      if (mounted) {
        setState(() {
          if (isEmblemSide) {
            _isUploadingEmblem = false;
          } else {
            _isUploadingPortrait = false;
          }
        });
      }
    }
  }

  Future<void> _selectCompanyCountry() async {
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '注册国家',
      options: qualificationCountryOptions
          .map(
            (QualificationCountryOption item) =>
                SelectableSheetOption<String>(
                  value: item.label,
                  label: item.label,
                ),
          )
          .toList(growable: false),
      initialSelectedValues: _selectedCompanyCountry == null
          ? const <String>[]
          : <String>[_selectedCompanyCountry!],
      multiple: false,
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    setState(() {
      _selectedCompanyCountry = result.first;
    });
  }

  void _handleNext() {
    if (_isCompany && !_isCompanyNextEnabled) {
      return;
    }

    _draft.serviceProviderCompanyName =
        _serviceProviderCompanyNameController.text.trim();
    _draft.unifiedCreditCode = _creditCodeController.text.trim();
    _draft.legalPerson = _legalPersonController.text.trim();
    _draft.contactPerson = _contactPersonController.text.trim();
    _draft.contactPhone = _phoneController.text.trim();
    _draft.contactEmail = _emailController.text.trim();
    _draft.website = _websiteController.text.trim();

    _draft.companyName = _companyNameController.text.trim();
    _draft.companyManagerName = _companyManagerNameController.text.trim();
    _draft.companyPhone = _companyPhoneController.text.trim();
    _draft.companyEmail = _companyEmailController.text.trim();
    _draft.companyCountryLabel = _selectedCompanyCountry?.trim() ?? '';
    _draft.companyCountryCode = qualificationCountryCodeFromLabel(
      _draft.companyCountryLabel,
    );

    context.push(
      RoutePaths.qualificationCertificationStepTwo,
      extra: widget.args,
    );
  }

  String _resolveErrorMessage(Object error) {
    final String message = error.toString();
    if (message.startsWith('ApiException(') || message.startsWith('Exception: ')) {
      return '上传失败，请稍后重试';
    }
    return message;
  }

  @override
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
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: const Text(
          '资质认证',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _isCompany ? '为了您的企业账户安全，请完成实名认证' : '为了您的企业账户安全，请完成实名认证',
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: QualificationProgressStepper(
                  labels: _steps,
                  currentStep: 1,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _FormCard(
                  child: _isCompany
                      ? _CompanyBasicInfoForm(
                          companyNameController: _companyNameController,
                          managerNameController: _companyManagerNameController,
                          phoneController: _companyPhoneController,
                          emailController: _companyEmailController,
                          selectedCountry: _selectedCompanyCountry,
                          onCountryTap: _selectCompanyCountry,
                        )
                      : _ServiceProviderBasicInfoForm(
                          companyNameController:
                              _serviceProviderCompanyNameController,
                          creditCodeController: _creditCodeController,
                          legalPersonController: _legalPersonController,
                          contactPersonController: _contactPersonController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          websiteController: _websiteController,
                          idCardEmblemImage: _idCardEmblemImage,
                          idCardPortraitImage: _idCardPortraitImage,
                          isEmblemUploading: _isUploadingEmblem,
                          isPortraitUploading: _isUploadingPortrait,
                          onEmblemTap: () =>
                              _pickIdentityCardImage(isEmblemSide: true),
                          onPortraitTap: () =>
                              _pickIdentityCardImage(isEmblemSide: false),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFF0F0F0)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isCompany ? (_isCompanyNextEnabled ? _handleNext : null) : _handleNext,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF096DD9),
                disabledBackgroundColor: const Color(0xFFD9D9D9),
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '下一步',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceProviderBasicInfoForm extends StatelessWidget {
  const _ServiceProviderBasicInfoForm({
    required this.companyNameController,
    required this.creditCodeController,
    required this.legalPersonController,
    required this.contactPersonController,
    required this.phoneController,
    required this.emailController,
    required this.websiteController,
    required this.idCardEmblemImage,
    required this.idCardPortraitImage,
    required this.isEmblemUploading,
    required this.isPortraitUploading,
    required this.onEmblemTap,
    required this.onPortraitTap,
  });

  final TextEditingController companyNameController;
  final TextEditingController creditCodeController;
  final TextEditingController legalPersonController;
  final TextEditingController contactPersonController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController websiteController;
  final PickedUploadFile? idCardEmblemImage;
  final PickedUploadFile? idCardPortraitImage;
  final bool isEmblemUploading;
  final bool isPortraitUploading;
  final VoidCallback onEmblemTap;
  final VoidCallback onPortraitTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _QualificationTextField(
          label: '企业名称',
          hintText: '请输入营业执照上的企业全称',
          controller: companyNameController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '统一社会信用代码',
          hintText: '请输入',
          controller: creditCodeController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '法人姓名',
          hintText: '请输入',
          controller: legalPersonController,
          required: true,
        ),
        const SizedBox(height: 16),
        _SectionLabel(label: '法人身份证', required: true),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _UploadCard(
                pickedFile: idCardEmblemImage,
                imageAsset: 'assets/images/qualification_id_emblem.png',
                label: '上传国徽面',
                isUploading: isEmblemUploading,
                onTap: onEmblemTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UploadCard(
                pickedFile: idCardPortraitImage,
                imageAsset: 'assets/images/qualification_id_portrait.png',
                label: '上传人像面',
                isUploading: isPortraitUploading,
                onTap: onPortraitTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '官方联系人',
          hintText: '请输入',
          controller: contactPersonController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '联系电话',
          hintText: '请输入',
          controller: phoneController,
          required: true,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '邮箱',
          hintText: '请输入',
          controller: emailController,
          required: true,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '公司官网',
          hintText: '选填',
          controller: websiteController,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

class _CompanyBasicInfoForm extends StatelessWidget {
  const _CompanyBasicInfoForm({
    required this.companyNameController,
    required this.managerNameController,
    required this.phoneController,
    required this.emailController,
    required this.selectedCountry,
    required this.onCountryTap,
  });

  final TextEditingController companyNameController;
  final TextEditingController managerNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final String? selectedCountry;
  final VoidCallback onCountryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _QualificationTextField(
          label: '企业名称',
          hintText: '请输入营业执照上的企业全称',
          controller: companyNameController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationSelectorField(
          label: '注册国家',
          value: selectedCountry,
          hintText: '请选择',
          required: true,
          onTap: onCountryTap,
          fieldKey: const Key('qualification_company_country_selector'),
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '负责人姓名',
          hintText: '请输入',
          controller: managerNameController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '联系电话',
          hintText: '请输入',
          controller: phoneController,
          required: true,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '联系邮箱',
          hintText: '请输入',
          controller: emailController,
          required: true,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    this.required = false,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
        if (required) ...<Widget>[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFFF4D4F),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
        ],
      ],
    );
  }
}

class _QualificationTextField extends StatelessWidget {
  const _QualificationTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.required = false,
    this.keyboardType,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(label: label, required: required),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 14,
                height: 20 / 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFBFBFBF),
                  fontSize: 14,
                  height: 20 / 14,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QualificationSelectorField extends StatelessWidget {
  const _QualificationSelectorField({
    required this.label,
    required this.hintText,
    required this.onTap,
    this.value,
    this.required = false,
    this.fieldKey,
  });

  final String label;
  final String hintText;
  final String? value;
  final VoidCallback onTap;
  final bool required;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(label: label, required: required),
        const SizedBox(height: 8),
        InkWell(
          key: fieldKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    hasValue ? value! : hintText,
                    style: TextStyle(
                      color: hasValue
                          ? const Color(0xFF262626)
                          : const Color(0xFFBFBFBF),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF8C8C8C),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.imageAsset,
    required this.label,
    required this.onTap,
    this.pickedFile,
    this.isUploading = false,
  });

  final String imageAsset;
  final String label;
  final VoidCallback onTap;
  final PickedUploadFile? pickedFile;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: <Widget>[
          Container(
            height: 116,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildPreview(),
                if (isUploading)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0x66000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final String? path = pickedFile?.path;
    if (path == null || path.isEmpty) {
      return Image.asset(
        imageAsset,
        width: 159,
        height: 116,
        fit: BoxFit.contain,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.file(
        File(path),
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            imageAsset,
            width: 159,
            height: 116,
            fit: BoxFit.contain,
          );
        },
      ),
    );
  }
}
