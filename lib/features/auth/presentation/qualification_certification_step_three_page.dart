import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/unsaved_changes_exit_guard.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../application/qualification_upload_helper.dart';
import '../../me/presentation/country_options_bottom_sheet.dart';
import '../../employer/data/employer_providers.dart';
import '../../service_detail/presentation/app_result_page.dart';
import '../../visa/data/provider_providers.dart';
import 'qualification_certification_flow.dart';
import 'widgets/qualification_progress_stepper.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 记录第三步表单的关键字段快照，用于判断当前页面是否存在未保存改动。
class _QualificationStepThreeSnapshot {
  const _QualificationStepThreeSnapshot({
    required this.selectedCountries,
    required this.yearsOfService,
  });

  final List<String> selectedCountries;
  final String yearsOfService;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is _QualificationStepThreeSnapshot &&
        listEquals(other.selectedCountries, selectedCountries) &&
        other.yearsOfService == yearsOfService;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(selectedCountries), yearsOfService);
}

class QualificationCertificationStepThreePage extends ConsumerStatefulWidget {
  const QualificationCertificationStepThreePage({
    super.key,
    required this.args,
  });

  final QualificationCertificationPageArgs args;

  @override
  ConsumerState<QualificationCertificationStepThreePage> createState() =>
      _QualificationCertificationStepThreePageState();
}

class _QualificationCertificationStepThreePageState
    extends ConsumerState<QualificationCertificationStepThreePage> {
  final TextEditingController _experienceController = TextEditingController();
  late final List<String> _selectedCountries;
  late _QualificationStepThreeSnapshot _initialSnapshot;
  bool _isSubmitting = false;
  bool _allowDirectPop = false;
  bool _skipSuccessNavigationForTest = false;

  QualificationCertificationRole get _role => widget.args.role;
  QualificationCertificationDraft get _draft => widget.args.draft;
  List<String> get _steps => <String>[
    tr('认证流程.基本信息'),
    tr('认证流程.资质证明'),
    tr('认证流程.服务信息'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCountries = _draft.serviceCountryLabels.isEmpty
        ? <String>[]
        : List<String>.of(_draft.serviceCountryLabels);
    if (_draft.yearsOfService > 0) {
      _experienceController.text = _draft.yearsOfService.toString();
    }
    _initialSnapshot = _buildCurrentSnapshot();
  }

  @override
  void dispose() {
    _experienceController.dispose();
    super.dispose();
  }

  /// 采集当前表单关键字段，用于和初始值做快照比对。
  _QualificationStepThreeSnapshot _buildCurrentSnapshot() {
    return _QualificationStepThreeSnapshot(
      selectedCountries: List<String>.of(_selectedCountries),
      yearsOfService: _experienceController.text.trim(),
    );
  }

  /// 统一处理离开第三步页面的动作，存在未保存改动时先弹确认框。
  Future<void> _handleAttemptLeave() async {
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: _buildCurrentSnapshot() != _initialSnapshot,
    );
    if (!mounted || !canLeave) {
      return;
    }

    await _leavePageAfterPopScopeUnlocked();
  }

  /// 确认退出后先刷新 `PopScope.canPop`，再执行真实离页，避免同一帧再次被拦截。
  Future<void> _leavePageAfterPopScopeUnlocked() async {
    if (_allowDirectPop) {
      return;
    }

    setState(() {
      _allowDirectPop = true;
    });

    // 关键时序：等待下一帧让 PopScope 读到最新 canPop，再触发真实返回。
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _openExpectedCountrySheet() async {
    final result = await showCountryOptionsBottomSheet(
      context: context,
      ref: ref,
      title: qualificationCountryLabel(_role),
      initialSelectedValues: _selectedCountries,
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _selectedCountries
        ..clear()
        ..addAll(result.map((item) => item.nameZh.trim()));
    });
  }

  void _removeSelectedCountry(String country) {
    setState(() {
      _selectedCountries.remove(country);
    });
  }

  /// 在最终提交前兜底校验必填资质图片，避免用户绕过前序步骤直接提交。
  bool _validateRequiredImagesBeforeSubmit() {
    if (_role == QualificationCertificationRole.serviceProvider &&
        _draft.idCardEmblemDoc == null) {
      AppToast.show('请上传身份证国徽面'.tr());
      return false;
    }
    if (_role == QualificationCertificationRole.serviceProvider &&
        _draft.idCardPortraitDoc == null) {
      AppToast.show('请上传身份证人像面'.tr());
      return false;
    }
    if (_draft.businessLicenseDoc == null) {
      AppToast.show('认证流程.请上传营业执照'.tr());
      return false;
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) {
      return;
    }
    if (!_validateRequiredImagesBeforeSubmit()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final countries = await loadCountries(ref);
      _draft.serviceCountryLabels = List<String>.of(_selectedCountries);
      _draft.serviceCountryCodes = mapCountryLabelsToCodes(
        _selectedCountries,
        countries,
      );
      _draft.yearsOfService =
          int.tryParse(_experienceController.text.trim()) ?? 0;
      await QualificationUploadHelper.uploadDraftQualifications(
        ref: ref,
        role: _role,
        draft: _draft,
      );
      if (_role == QualificationCertificationRole.company) {
        await ref
            .read(employerServiceProvider)
            .updateEmployerProfile(request: _draft.toEmployerUpdateRequest());
      } else {
        await ref
            .read(providerServiceProvider)
            .updateMyProfile(request: _draft.toProviderUpdateRequest());
      }
      if (!mounted) {
        return;
      }
      // 提交成功后允许页面继续跳转，避免被未保存拦截误伤。
      _allowDirectPop = true;
      if (_skipSuccessNavigationForTest) {
        return;
      }
      context.push(
        RoutePaths.appResult,
        extra: AppResultPageArgs(
          pageTitle: tr('认证流程.资质认证'),
          resultTitle: tr('认证流程.信息已提交'),
          tipText: tr('认证流程.审核提示'),
          actionLabel: tr('认证流程.进入首页'),
          action: AppResultAction.go(RoutePaths.home),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppToast.show('认证流程.提交失败'.tr());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 仅供测试直接触发最终提交，避免测试依赖真实路由跳转。
  Future<void> debugSubmitForTest() async {
    _skipSuccessNavigationForTest = true;
    try {
      await _handleSubmit();
    } finally {
      _skipSuccessNavigationForTest = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowDirectPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || _allowDirectPop) {
          return;
        }
        await _handleAttemptLeave();
      },
      child: Scaffold(
        key: AppTestKeys.pageQualificationCertificationStepThree,
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
                  padding: EdgeInsets.symmetric(horizontal: 16),
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
                    currentStep: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              qualificationCountryLabel(_role),
                              style: TestStyle.pingFangRegular(
                                fontSize: 14,
                                color: Color(0xFF262626),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '认证流程.可多选'.tr(),
                              style: TestStyle.pingFangRegular(
                                fontSize: 13,
                                color: Color(0xFF8C8C8C),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '*',
                              style: TestStyle.regular(
                                fontSize: 14,
                                color: Color(0xFFFF4D4F),
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              key: AppTestKeys
                                  .actionQualificationServiceCountrySelect,
                              onTap: _openExpectedCountrySheet,
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Center(
                                  child: SvgPicture.asset(
                                    'assets/images/add_circle.svg',
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0x99262626),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedCountries
                              .map(
                                (String country) => _CountryTag(
                                  label: country,
                                  onTap: () => _removeSelectedCountry(country),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: <Widget>[
                            Text(
                              '认证流程.从业年限'.tr(),
                              style: TestStyle.pingFangRegular(
                                fontSize: 14,
                                color: Color(0xFF262626),
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '*',
                              style: TestStyle.regular(
                                fontSize: 14,
                                color: Color(0xFFFF4D4F),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7FA),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: TextField(
                                  key: AppTestKeys
                                      .fieldQualificationYearsOfService,
                                  controller: _experienceController,
                                  keyboardType: TextInputType.number,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TestStyle.pingFangRegular(
                                    fontSize: 14,
                                    color: Color(0xFF262626),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '通用.请输入'.tr(),
                                    hintStyle: TestStyle.pingFangRegular(
                                      fontSize: 14,
                                      color: Color(0xFFBFBFBF),
                                    ),
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '认证流程.年'.tr(),
                              style: TestStyle.pingFangMedium(
                                fontSize: 14,
                                color: Color(0xFF262626),
                              ),
                            ),
                          ],
                        ),
                      ],
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
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: _handleAttemptLeave,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD9D9D9)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '认证流程.上一步'.tr(),
                        style: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: Color(0xFF171A1D),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      key: AppTestKeys.actionQualificationSubmit,
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF096DD9),
                        disabledBackgroundColor: const Color(0xFFD9D9D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        '认证流程.提交审核'.tr(),
                        style: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryTag extends StatelessWidget {
  const _CountryTag({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF91C3FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: TestStyle.regular(fontSize: 14, color: Color(0xFF096DD9)),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/qualification_tag_close.svg',
              width: 9,
              height: 9,
            ),
          ],
        ),
      ),
    );
  }
}
