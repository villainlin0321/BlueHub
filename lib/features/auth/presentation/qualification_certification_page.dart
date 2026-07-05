import '../../../shared/widgets/app_toast.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:europepass/shared/ui/test_keys.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/models/dictionary_models.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../shared/widgets/unsaved_changes_exit_guard.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../me/presentation/country_options_bottom_sheet.dart';
import 'qualification_certification_flow.dart';
import 'qualification_preview_resolver.dart';
import 'widgets/qualification_preview_image.dart';
import 'widgets/qualification_progress_stepper.dart';

import 'package:europepass/shared/ui/test_style.dart';

class QualificationCertificationPage extends ConsumerStatefulWidget {
  const QualificationCertificationPage({super.key, required this.args});

  final QualificationCertificationPageArgs args;

  @override
  ConsumerState<QualificationCertificationPage> createState() =>
      _QualificationCertificationPageState();
}

class _QualificationCertificationPageState
    extends ConsumerState<QualificationCertificationPage> {
  final TextEditingController _serviceProviderCompanyNameController =
      TextEditingController();
  final TextEditingController _creditCodeController = TextEditingController();
  final TextEditingController _legalPersonController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyIndustryController =
      TextEditingController();
  final TextEditingController _companySizeController = TextEditingController();
  final TextEditingController _companyWebsiteController =
      TextEditingController();
  final TextEditingController _companyFoundedYearController =
      TextEditingController();
  final TextEditingController _companyCityController = TextEditingController();
  final TextEditingController _companyManagerNameController =
      TextEditingController();
  final TextEditingController _companyPhoneController = TextEditingController();
  final TextEditingController _companyEmailController = TextEditingController();

  PickedUploadFile? _idCardEmblemImage;
  PickedUploadFile? _idCardPortraitImage;
  String? _selectedCompanyCountry;
  String? _selectedCompanyCountryCode;
  late String _initialSnapshotSignature;

  QualificationCertificationRole get _role => widget.args.role;
  bool get _isCompany => _role == QualificationCertificationRole.company;
  QualificationCertificationDraft get _draft => widget.args.draft;
  List<String> get _steps => <String>[
    tr('认证流程.基本信息'),
    tr('认证流程.资质证明'),
    tr('认证流程.服务信息'),
  ];

  bool get _isCompanyNextEnabled {
    return _companyNameController.text.trim().isNotEmpty &&
        _companyIndustryController.text.trim().isNotEmpty &&
        _companySizeController.text.trim().isNotEmpty &&
        _companyWebsiteController.text.trim().isNotEmpty &&
        _isValidFoundedYear(_companyFoundedYearController.text) &&
        (_selectedCompanyCountry?.trim().isNotEmpty ?? false) &&
        _companyCityController.text.trim().isNotEmpty &&
        _companyManagerNameController.text.trim().isNotEmpty &&
        _companyPhoneController.text.trim().isNotEmpty &&
        _isValidEmail(_companyEmailController.text);
  }

  @override
  void initState() {
    super.initState();
    _serviceProviderCompanyNameController.text =
        _draft.serviceProviderCompanyName;
    _creditCodeController.text = _draft.unifiedCreditCode;
    _legalPersonController.text = _draft.legalPerson;
    _contactPersonController.text = _draft.contactPerson;
    _phoneController.text = _draft.contactPhone;
    _emailController.text = _draft.contactEmail;
    _websiteController.text = _draft.website;
    _companyNameController.text = _draft.companyName;
    _companyIndustryController.text = _draft.companyIndustry;
    _companySizeController.text = _draft.companySize;
    _companyWebsiteController.text = _draft.companyWebsite;
    _companyFoundedYearController.text = _draft.companyFoundedYear;
    _companyCityController.text = _draft.companyCity;
    _companyManagerNameController.text = _draft.companyManagerName;
    _companyPhoneController.text = _draft.companyPhone;
    _companyEmailController.text = _draft.companyEmail;
    _selectedCompanyCountry = _draft.companyCountryLabel.isEmpty
        ? null
        : _draft.companyCountryLabel;
    _selectedCompanyCountryCode = _draft.companyCountryCode.trim().isEmpty
        ? null
        : _draft.companyCountryCode.trim();
    if (_draft.idCardEmblemDoc != null) {
      final String? previewPath =
          QualificationPreviewResolver.resolvePreviewPath(
            _draft.idCardEmblemDoc,
          );
      if (previewPath != null) {
        _idCardEmblemImage = PickedUploadFile(
          id: 'qualification-id-emblem',
          path: previewPath,
          name: _draft.idCardEmblemDoc!.docName,
          isImage: true,
          sizeLabel: '',
          sourceType: UploadSourceType.gallery,
          state: UploadItemState.success,
        );
      }
    }
    if (_draft.idCardPortraitDoc != null) {
      final String? previewPath =
          QualificationPreviewResolver.resolvePreviewPath(
            _draft.idCardPortraitDoc,
          );
      if (previewPath != null) {
        _idCardPortraitImage = PickedUploadFile(
          id: 'qualification-id-portrait',
          path: previewPath,
          name: _draft.idCardPortraitDoc!.docName,
          isImage: true,
          sizeLabel: '',
          sourceType: UploadSourceType.gallery,
          state: UploadItemState.success,
        );
      }
    }
    _companyNameController.addListener(_handleCompanyFormChanged);
    _companyIndustryController.addListener(_handleCompanyFormChanged);
    _companySizeController.addListener(_handleCompanyFormChanged);
    _companyWebsiteController.addListener(_handleCompanyFormChanged);
    _companyFoundedYearController.addListener(_handleCompanyFormChanged);
    _companyCityController.addListener(_handleCompanyFormChanged);
    _companyManagerNameController.addListener(_handleCompanyFormChanged);
    _companyPhoneController.addListener(_handleCompanyFormChanged);
    _companyEmailController.addListener(_handleCompanyFormChanged);
    _initialSnapshotSignature = _buildCurrentSnapshotSignature();
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
    _companyIndustryController.dispose();
    _companySizeController.dispose();
    _companyWebsiteController.dispose();
    _companyFoundedYearController.dispose();
    _companyCityController.dispose();
    _companyManagerNameController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  void _handleCompanyFormChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// 汇总第一页所有会影响提交结果的字段，统一作为未保存改动的比较口径。
  String _buildCurrentSnapshotSignature() {
    final List<String> values = <String>[
      _serviceProviderCompanyNameController.text.trim(),
      _creditCodeController.text.trim(),
      _legalPersonController.text.trim(),
      _contactPersonController.text.trim(),
      _phoneController.text.trim(),
      _emailController.text.trim(),
      _websiteController.text.trim(),
      _companyNameController.text.trim(),
      _companyIndustryController.text.trim(),
      _companySizeController.text.trim(),
      _companyWebsiteController.text.trim(),
      _companyFoundedYearController.text.trim(),
      _companyCityController.text.trim(),
      _companyManagerNameController.text.trim(),
      _companyPhoneController.text.trim(),
      _companyEmailController.text.trim(),
      _selectedCompanyCountry?.trim() ?? '',
      _selectedCompanyCountryCode?.trim() ?? '',
      _idCardEmblemImage?.path ?? '',
      _idCardPortraitImage?.path ?? '',
    ];
    return values.join('||');
  }

  /// 统一同步第一页输入内容到流程草稿，确保后续步骤拿到的是最新状态。
  void _syncDraftFromForm() {
    _draft.serviceProviderCompanyName = _serviceProviderCompanyNameController
        .text
        .trim();
    _draft.unifiedCreditCode = _creditCodeController.text.trim();
    _draft.legalPerson = _legalPersonController.text.trim();
    _draft.contactPerson = _contactPersonController.text.trim();
    _draft.contactPhone = _phoneController.text.trim();
    _draft.contactEmail = _emailController.text.trim();
    _draft.website = _websiteController.text.trim();

    _draft.companyName = _companyNameController.text.trim();
    _draft.companyIndustry = _companyIndustryController.text.trim();
    _draft.companySize = _companySizeController.text.trim();
    _draft.companyWebsite = _companyWebsiteController.text.trim();
    _draft.companyFoundedYear = _companyFoundedYearController.text.trim();
    _draft.companyManagerName = _companyManagerNameController.text.trim();
    _draft.companyPhone = _companyPhoneController.text.trim();
    _draft.companyEmail = _companyEmailController.text.trim();
    _draft.companyCountryLabel = _selectedCompanyCountry?.trim() ?? '';
    _draft.companyCountryCode = _selectedCompanyCountryCode?.trim() ?? '';
    _draft.companyCity = _companyCityController.text.trim();
  }

  /// 校验服务商第一页的必填身份证图片是否已经选择完成。
  bool _validateRequiredIdentityImages() {
    if (_idCardEmblemImage == null) {
      AppToast.show('请上传身份证国徽面'.tr());
      return false;
    }
    if (_idCardPortraitImage == null) {
      AppToast.show('请上传身份证人像面'.tr());
      return false;
    }
    return true;
  }

  /// 统一处理离开第一页页面的动作，存在未保存改动时先弹确认框。
  Future<void> _handleAttemptLeave() async {
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges:
          _buildCurrentSnapshotSignature() != _initialSnapshotSignature,
    );
    if (!mounted || !canLeave) {
      return;
    }
    context.go(RoutePaths.me);
  }

  /// 仅供测试注入已选身份证图片，避免测试依赖真实系统相册或相机。
  void debugSetIdentityImagesForTest({
    String? emblemPath,
    String? portraitPath,
  }) {
    setState(() {
      if (emblemPath != null) {
        _idCardEmblemImage = PickedUploadFile(
          id: 'qualification-id-emblem-debug',
          path: emblemPath,
          name: 'id-emblem.png',
          isImage: true,
          sizeLabel: '',
          sourceType: UploadSourceType.gallery,
          state: UploadItemState.success,
        );
        _draft.idCardEmblemDoc = UploadedQualificationDoc(
          docType: QualificationDocType.idCard,
          docName: tr('认证流程.法人身份证国徽面'),
          localPath: emblemPath,
        );
      }
      if (portraitPath != null) {
        _idCardPortraitImage = PickedUploadFile(
          id: 'qualification-id-portrait-debug',
          path: portraitPath,
          name: 'id-portrait.png',
          isImage: true,
          sizeLabel: '',
          sourceType: UploadSourceType.gallery,
          state: UploadItemState.success,
        );
        _draft.idCardPortraitDoc = UploadedQualificationDoc(
          docType: QualificationDocType.idCard,
          docName: tr('认证流程.法人身份证人像面'),
          localPath: portraitPath,
        );
      }
    });
  }

  bool _isValidEmail(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed);
  }

  bool _isValidFoundedYear(String value) {
    final int? foundedYear = int.tryParse(value.trim());
    return foundedYear != null && foundedYear > 0;
  }

  Future<void> _pickIdentityCardImage({required bool isEmblemSide}) async {
    final List<PickedUploadFile> files =
        await UploadPickerUtils.pickImagesWithSourceSheet(
          context: context,
          title: tr('上传.选择图片'),
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
        _idCardEmblemImage = pickedFile;
        _draft.idCardEmblemDoc = UploadedQualificationDoc(
          docType: QualificationDocType.idCard,
          docName: tr('认证流程.法人身份证国徽面'),
          localPath: pickedFile.path,
        );
      } else {
        _idCardPortraitImage = pickedFile;
        _draft.idCardPortraitDoc = UploadedQualificationDoc(
          docType: QualificationDocType.idCard,
          docName: tr('认证流程.法人身份证人像面'),
          localPath: pickedFile.path,
        );
      }
    });
  }

  Future<void> _selectCompanyCountry() async {
    final List<CountryVO>? result = await showCountryOptionsBottomSheet(
      context: context,
      ref: ref,
      title: tr('认证流程.注册国家'),
      initialSelectedValues: _selectedCompanyCountryCode == null
          ? const <String>[]
          : <String>[_selectedCompanyCountryCode!],
      multiple: false,
    );
    if (!mounted || result == null || result.isEmpty) {
      return;
    }
    setState(() {
      _selectedCompanyCountry = result.first.nameZh.trim();
      _selectedCompanyCountryCode = result.first.countryCode.trim();
    });
  }

  void _handleNext() {
    if (_isCompany && !_isCompanyNextEnabled) {
      return;
    }

    if (!_isCompany && !_validateRequiredIdentityImages()) {
      return;
    }

    _syncDraftFromForm();

    context.go(
      RoutePaths.qualificationCertificationStepTwo,
      extra: widget.args,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        await _handleAttemptLeave();
      },
      child: Scaffold(
        key: AppTestKeys.pageQualificationCertificationStepOne,
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: _handleAttemptLeave,
            icon: const AppSvgIcon(
              assetPath: 'assets/images/service_detail_back.svg',
              fallback: Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xE6000000),
            ),
          ),
          title: Text(
            '认证流程.资质认证'.tr(),
            style: TestStyle.pingFangMedium(
              fontSize: 17,
              color: Color(0xE6000000),
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
                    '认证流程.实名认证提示'.tr(),
                    style: TestStyle.pingFangRegular(
                      fontSize: 14,
                      color: Color(0xFF8C8C8C),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
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
                            industryController: _companyIndustryController,
                            companySizeController: _companySizeController,
                            websiteController: _companyWebsiteController,
                            foundedYearController:
                                _companyFoundedYearController,
                            managerNameController:
                                _companyManagerNameController,
                            phoneController: _companyPhoneController,
                            emailController: _companyEmailController,
                            selectedCountry: _selectedCompanyCountry,
                            cityController: _companyCityController,
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
                            isEmblemUploading: false,
                            isPortraitUploading: false,
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
              border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: SizedBox(
              height: 48,
              child: FilledButton(
                key: AppTestKeys.actionQualificationStepOneNext,
                onPressed: _isCompany
                    ? (_isCompanyNextEnabled ? _handleNext : null)
                    : _handleNext,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF096DD9),
                  disabledBackgroundColor: const Color(0xFFD9D9D9),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '认证流程.下一步'.tr(),
                  style: TestStyle.pingFangMedium(
                    fontSize: 16,
                    color: Colors.white,
                  ),
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
          label: '认证流程.企业名称'.tr(),
          hintText: '认证流程.营业执照企业全称'.tr(),
          controller: companyNameController,
          fieldKey: AppTestKeys.fieldQualificationCompanyName,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.统一社会信用代码'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: creditCodeController,
          fieldKey: AppTestKeys.fieldQualificationCreditCode,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.法人姓名'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: legalPersonController,
          fieldKey: AppTestKeys.fieldQualificationLegalPerson,
          required: true,
        ),
        const SizedBox(height: 16),
        _SectionLabel(label: '认证流程.法人身份证'.tr(), required: true),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            Expanded(
              child: _UploadCard(
                cardKey: AppTestKeys.actionQualificationIdCardEmblemUpload,
                pickedFile: idCardEmblemImage,
                imageAsset: 'assets/images/qualification_id_emblem.png',
                label: '认证流程.上传国徽面'.tr(),
                isUploading: isEmblemUploading,
                onTap: onEmblemTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _UploadCard(
                cardKey: AppTestKeys.actionQualificationIdCardPortraitUpload,
                pickedFile: idCardPortraitImage,
                imageAsset: 'assets/images/qualification_id_portrait.png',
                label: '认证流程.上传人像面'.tr(),
                isUploading: isPortraitUploading,
                onTap: onPortraitTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.官方联系人'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: contactPersonController,
          fieldKey: AppTestKeys.fieldQualificationContactPerson,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.联系电话'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: phoneController,
          fieldKey: AppTestKeys.fieldQualificationContactPhone,
          required: true,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.邮箱'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: emailController,
          fieldKey: AppTestKeys.fieldQualificationContactEmail,
          required: true,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.公司官网'.tr(),
          hintText: '通用.选填'.tr(),
          controller: websiteController,
          fieldKey: AppTestKeys.fieldQualificationWebsite,
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

class _CompanyBasicInfoForm extends StatelessWidget {
  const _CompanyBasicInfoForm({
    required this.companyNameController,
    required this.industryController,
    required this.companySizeController,
    required this.websiteController,
    required this.foundedYearController,
    required this.managerNameController,
    required this.phoneController,
    required this.emailController,
    required this.selectedCountry,
    required this.cityController,
    required this.onCountryTap,
  });

  final TextEditingController companyNameController;
  final TextEditingController industryController;
  final TextEditingController companySizeController;
  final TextEditingController websiteController;
  final TextEditingController foundedYearController;
  final TextEditingController managerNameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final String? selectedCountry;
  final TextEditingController cityController;
  final VoidCallback onCountryTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _QualificationTextField(
          label: '认证流程.企业名称'.tr(),
          hintText: '认证流程.营业执照企业全称'.tr(),
          controller: companyNameController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.所属行业'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: industryController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.公司规模'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: companySizeController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.官网地址'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: websiteController,
          required: true,
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.成立年份'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: foundedYearController,
          required: true,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _QualificationSelectorField(
          label: '认证流程.注册国家'.tr(),
          value: selectedCountry,
          hintText: '通用.请选择'.tr(),
          required: true,
          onTap: onCountryTap,
          fieldKey: const Key('qualification_company_country_selector'),
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.所在城市'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: cityController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.负责人姓名'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: managerNameController,
          required: true,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.联系电话'.tr(),
          hintText: '通用.请输入'.tr(),
          controller: phoneController,
          required: true,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _QualificationTextField(
          label: '认证流程.联系邮箱'.tr(),
          hintText: '通用.请输入'.tr(),
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
  const _SectionLabel({required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: TestStyle.regular(fontSize: 14, color: Color(0xFF262626)),
        ),
        if (required) ...<Widget>[
          const SizedBox(width: 4),
          Text(
            '*',
            style: TestStyle.regular(fontSize: 14, color: Color(0xFFFF4D4F)),
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
    this.fieldKey,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;
  final Key? fieldKey;

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
              key: fieldKey,
              controller: controller,
              keyboardType: keyboardType,
              textAlignVertical: TextAlignVertical.center,
              style: TestStyle.regular(fontSize: 14, color: Color(0xFF262626)),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TestStyle.regular(
                  fontSize: 14,
                  color: Color(0xFFBFBFBF),
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
                    style: TestStyle.regular(
                      fontSize: 14,
                      color: hasValue
                          ? const Color(0xFF262626)
                          : const Color(0xFFBFBFBF),
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
    this.cardKey,
    this.pickedFile,
    this.isUploading = false,
  });

  final String imageAsset;
  final String label;
  final VoidCallback onTap;
  final Key? cardKey;
  final PickedUploadFile? pickedFile;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: cardKey,
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
            style: TestStyle.regular(fontSize: 12, color: Color(0xFF262626)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return QualificationPreviewImage(
      previewPath: pickedFile?.path,
      placeholderAsset: imageAsset,
      fit: BoxFit.cover,
      placeholderFit: BoxFit.contain,
      borderRadius: BorderRadius.circular(8),
    );
  }
}
