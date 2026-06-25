import 'dart:io';
import '../../../shared/widgets/app_toast.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/network/models/dictionary_models.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/models/app_currency.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../../../shared/widgets/app_currency_bottom_sheet.dart';
import '../../../shared/widgets/app_text_input_dialog.dart';
import '../../../shared/widgets/field_trailing_selector.dart';
import '../data/resume_models.dart';
import '../data/dictionary_providers.dart';
import '../data/resume_providers.dart';
import 'add_education_experience_page.dart';
import 'add_skill_certificate_page.dart';
import 'add_work_experience_page.dart';
import 'country_options_bottom_sheet.dart';
import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';

/// 编辑页的进入模式。
enum ResumeEditorMode { create, edit }

/// 简历编辑页的路由参数。
class ResumeEditorArgs {
  const ResumeEditorArgs.create({this.isPublic = true, this.resumeId})
    : mode = ResumeEditorMode.create,
      resume = null;

  ResumeEditorArgs.edit(this.resume)
    : mode = ResumeEditorMode.edit,
      isPublic = resume?.isPublic ?? true,
      resumeId = resume?.resumeId;

  final ResumeEditorMode mode;
  final ResumeVO? resume;
  final bool isPublic;
  final int? resumeId;
}

/// 简历草稿数据。
class ResumeDraft {
  const ResumeDraft({
    this.name = '',
    this.region = '',
    this.age = '',
    this.gender = '',
    this.phone = '',
    this.salary = '',
    this.salaryCurrency = 'EUR',
    this.jobTitle = '',
    this.duration = '',
    this.summary = '',
    this.isPublic = true,
  });

  final String name;
  final String region;
  final String age;
  final String gender;
  final String phone;
  final String salary;
  final String salaryCurrency;
  final String jobTitle;
  final String duration;
  final String summary;
  final bool isPublic;
}

class _EditorBasicInfoViewData {
  const _EditorBasicInfoViewData({
    required this.name,
    required this.region,
    required this.age,
    required this.gender,
    required this.phone,
    required this.avatarUrl,
    required this.avatarFallbackText,
  });

  final String name;
  final String region;
  final String age;
  final String gender;
  final String phone;
  final String avatarUrl;
  final String avatarFallbackText;
}

/// 简历预览页所需的真实数据快照。
class ResumePreviewArgs {
  const ResumePreviewArgs({
    required this.draft,
    required this.avatarUrl,
    required this.positions,
    required this.countries,
    required this.languages,
    required this.experiences,
    required this.certificates,
    required this.educations,
  });

  final ResumeDraft draft;
  final String avatarUrl;
  final List<String> positions;
  final List<String> countries;
  final List<String> languages;
  final List<ResumePreviewExperience> experiences;
  final List<ResumePreviewCertificate> certificates;
  final List<ResumePreviewEducation> educations;
}

/// 预览页工作经历模型。
class ResumePreviewExperience {
  const ResumePreviewExperience({
    required this.company,
    required this.period,
    required this.role,
    required this.summary,
  });

  final String company;
  final String period;
  final String role;
  final String summary;
}

/// 预览页技能证书模型。
class ResumePreviewCertificate {
  const ResumePreviewCertificate({
    required this.title,
    required this.period,
    required this.issuer,
    this.localImagePaths = const <String>[],
    this.networkImageUrls = const <String>[],
  });

  final String title;
  final String period;
  final String issuer;
  final List<String> localImagePaths;
  final List<String> networkImageUrls;
}

/// 预览页教育经历模型。
class ResumePreviewEducation {
  const ResumePreviewEducation({
    required this.school,
    required this.period,
    required this.major,
  });

  final String school;
  final String period;
  final String major;
}

/// 我的简历编辑页。
class MyResumeEditorPage extends ConsumerStatefulWidget {
  const MyResumeEditorPage({super.key, required this.args});

  final ResumeEditorArgs args;

  @override
  ConsumerState<MyResumeEditorPage> createState() => _MyResumeEditorPageState();
}

class _MyResumeEditorPageState extends ConsumerState<MyResumeEditorPage> {
  late final ResumeVO? _resume;
  late final ResumeDraft _draft;
  late final List<String> _jobTags;
  late final List<String> _countryTags;
  late final List<_ResumeLanguage> _languages;
  late final List<_ResumeExperience> _experiences;
  late final List<_ResumeCertificate> _certificates;
  late final List<_ResumeEducation> _educations;
  late final TextEditingController _salaryValueController;
  late final TextEditingController _salaryMaxValueController;
  late String _selfEvaluation;
  late AppCurrency _selectedSalaryCurrency;
  bool _isSaving = false;
  bool _didSave = false;

  /// 当前页面是否为创建模式。
  bool get _isCreateMode => widget.args.mode == ResumeEditorMode.create;

  /// 当前编辑目标的简历 ID；多简历场景优先使用显式传入的 ID。
  int? get _targetResumeId => widget.args.resumeId ?? _resume?.resumeId;

  String get _salaryValue => _salaryValueController.text.trim();

  String get _salaryMaxValue => _salaryMaxValueController.text.trim();

  void _handleCompletenessFieldChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  /// 当前页面基于本地编辑状态实时计算简历完整度。
  int get _completionRate {
    final dynamic user = ref.read(authSessionProvider).user;
    final String currentLocation = _buildBasicInfoViewData(user).region;
    return computeResumeCompleteness(
      targetPositions: _jobTags,
      targetCountries: _countryTags,
      currentLocation: currentLocation,
      salaryMin: _parseSalaryMin(),
      salaryMax: _parseSalaryMax(),
      salaryCurrency: _selectedSalaryCurrency.apiValue,
      hasLatestExperience: _experiences.isNotEmpty,
    ).clamp(0, 100);
  }

  @override
  void initState() {
    super.initState();
    _resume = widget.args.resume;
    _draft = _resolveDraft(_resume, isPublic: widget.args.isPublic);
    _jobTags = _buildJobTags(_resume);
    _countryTags = _buildCountryTags(_resume);
    _languages = _buildLanguages(_resume);
    _experiences = _buildExperiences(_resume);
    _certificates = _buildCertificates(_resume);
    _educations = _buildEducations(_resume);
    _salaryValueController = TextEditingController(
      text: _extractSalaryValue(_draft.salary),
    );
    _salaryMaxValueController = TextEditingController(
      text: _extractSalaryMaxValue(_draft.salary),
    );
    _selfEvaluation = _draft.summary;
    _selectedSalaryCurrency = AppCurrency.fromApiValue(
      _draft.salaryCurrency,
      fallback: AppCurrency.eur,
    );
    _salaryValueController.addListener(_handleCompletenessFieldChanged);
    _salaryMaxValueController.addListener(_handleCompletenessFieldChanged);
  }

  @override
  void dispose() {
    _salaryValueController.removeListener(_handleCompletenessFieldChanged);
    _salaryMaxValueController.removeListener(_handleCompletenessFieldChanged);
    _salaryValueController.dispose();
    _salaryMaxValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildCompletionSection(),
            const SizedBox(height: 2),
            _buildBasicInfoSection(),
            const SizedBox(height: 2),
            _buildJobIntentionSection(),
            const SizedBox(height: 2),
            _buildWorkExperienceSection(),
            const SizedBox(height: 2),
            _buildLanguageSection(),
            const SizedBox(height: 2),
            _buildCertificateSection(),
            const SizedBox(height: 2),
            _buildEducationSection(),
            const SizedBox(height: 2),
            _buildSelfEvaluationSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  /// 使用真实接口数据组装编辑页草稿，创建模式保留空白初始值。
  ResumeDraft _resolveDraft(ResumeVO? resume, {required bool isPublic}) {
    final WorkExperienceVO? firstExperience =
        resume == null || resume.workExperiences.isEmpty
        ? null
        : resume.workExperiences.first;

    if (resume == null) {
      return ResumeDraft(salaryCurrency: 'EUR', isPublic: isPublic);
    }

    return ResumeDraft(
      name: resume.basicInfo.realName,
      region: resume.basicInfo.currentLocation,
      age: resume.basicInfo.age > 0 ? resume.basicInfo.age.toString() : '',
      gender: resume.basicInfo.gender,
      phone: resume.basicInfo.phone,
      salary: _formatSalaryText(resume.jobIntention),
      salaryCurrency: resume.jobIntention.salaryCurrency.isEmpty
          ? 'EUR'
          : resume.jobIntention.salaryCurrency,
      jobTitle: _buildDraftJobTitle(firstExperience),
      duration: _formatExperiencePeriod(
        startDate: firstExperience?.startDate ?? '',
        endDate: firstExperience?.endDate ?? '',
        isCurrent: firstExperience?.isCurrent ?? false,
      ),
      summary: resume.selfEvaluation,
      isPublic: resume.isPublic ?? isPublic,
    );
  }

  /// 根据第一条工作经历生成预览所需的职位文案。
  String _buildDraftJobTitle(WorkExperienceVO? experience) {
    if (experience == null) {
      return '';
    }

    final String role = experience.department.isEmpty
        ? experience.position
        : '${experience.department}·${experience.position}';
    if (experience.company.isEmpty) {
      return role;
    }
    return '${experience.company}·$role';
  }

  /// 将接口薪资区间格式化为编辑页使用的纯数值文案。
  String _formatSalaryText(JobIntentionVO jobIntention) {
    final String minText = _formatDouble(jobIntention.salaryMin);
    final String maxText = _formatDouble(jobIntention.salaryMax);
    if (jobIntention.salaryMin <= 0 && jobIntention.salaryMax <= 0) {
      return '';
    }
    if (jobIntention.salaryMax > 0) {
      return '$minText-$maxText';
    }
    return minText;
  }

  /// 构建期望职位标签，仅使用真实接口数据。
  List<String> _buildJobTags(ResumeVO? resume) {
    return List<String>.of(resume?.jobIntention.positions ?? const <String>[]);
  }

  /// 构建期望国家标签，仅使用真实接口数据。
  List<String> _buildCountryTags(ResumeVO? resume) {
    return List<String>.of(resume?.jobIntention.countries ?? const <String>[]);
  }

  /// 构建真实语言能力列表，保留接口返回的原始字段。
  List<_ResumeLanguage> _buildLanguages(ResumeVO? resume) {
    return (resume?.languages ?? const <LanguageAbilityVO>[])
        .map(
          (LanguageAbilityVO item) => _ResumeLanguage(
            langId: item.langId,
            language: item.language,
            certificate: item.certificate,
            level: item.level,
          ),
        )
        .toList();
  }

  /// 构建真实工作经历列表，避免继续混入本地示例内容。
  List<_ResumeExperience> _buildExperiences(ResumeVO? resume) {
    return (resume?.workExperiences ?? const <WorkExperienceVO>[])
        .map(
          (WorkExperienceVO item) => _ResumeExperience(
            expId: item.expId,
            company: item.company,
            department: item.department,
            position: item.position,
            startDate: item.startDate,
            endDate: item.endDate,
            isCurrent: item.isCurrent,
            summary: item.description,
          ),
        )
        .toList();
  }

  /// 构建真实技能证书列表，图片按本地路径或网络地址分类。
  List<_ResumeCertificate> _buildCertificates(ResumeVO? resume) {
    return (resume?.skillCertificates ?? const <SkillCertificateVO>[])
        .map(
          (SkillCertificateVO item) => _ResumeCertificate(
            certId: item.certId,
            title: item.name,
            level: item.level,
            authority: item.issuer,
            issuedAt: item.issuedDate,
            previewFilePaths:
                item.imageUrl.isNotEmpty && !_isNetworkPath(item.imageUrl)
                ? <String>[item.imageUrl]
                : const <String>[],
            previewImageUrls: _isNetworkPath(item.imageUrl)
                ? <String>[item.imageUrl]
                : const <String>[],
          ),
        )
        .toList();
  }

  /// 构建真实教育经历列表，保留专业、学历与年份。
  List<_ResumeEducation> _buildEducations(ResumeVO? resume) {
    return (resume?.educations ?? const <EducationVO>[])
        .map(
          (EducationVO item) => _ResumeEducation(
            eduId: item.eduId,
            school: item.school,
            major: item.major,
            degree: item.degree,
            startYear: item.startYear,
            endYear: item.endYear,
          ),
        )
        .toList();
  }

  /// 只保留薪资左侧输入值，以匹配当前页面布局。
  String _extractSalaryValue(String salary) {
    if (salary.contains('-')) {
      return salary.split('-').first.trim();
    }
    if (salary.contains('~')) {
      return salary.split('~').first.trim();
    }
    return salary.trim();
  }

  /// 提取薪资右侧上限值，用于展示真实最高期望。
  String _extractSalaryMaxValue(String salary) {
    if (salary.contains('-')) {
      return salary.split('-').last.trim();
    }
    if (salary.contains('~')) {
      return salary.split('~').last.trim();
    }
    return '';
  }

  /// 统一格式化工作经历时间段文案。
  String _formatExperiencePeriod({
    required String startDate,
    required String endDate,
    required bool isCurrent,
  }) {
    if (startDate.isEmpty && endDate.isEmpty) {
      return '';
    }
    if (isCurrent) {
      final String currentLabel = '我的.至今'.tr();
      return startDate.isEmpty ? currentLabel : '$startDate - $currentLabel';
    }
    if (startDate.isEmpty) {
      return endDate;
    }
    if (endDate.isEmpty) {
      return startDate;
    }
    return '$startDate - $endDate';
  }

  /// 将数值转成不带多余小数的字符串。
  String _formatDouble(double value) {
    if (value <= 0) {
      return '';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// 判断图片地址是否为网络资源。
  bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  /// 构建顶部导航栏。
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      scrolledUnderElevation: 0,
      leadingWidth: 44,
      leading: IconButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop(_didSave);
            return;
          }
          context.go(RoutePaths.myResume);
        },
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF262626),
        ),
      ),
      title: Text(
        '我的.我的简历'.tr(),
        style: TextStyle(
          color: Color(0xE6000000),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: GestureDetector(
              onTap: _openPreview,
              child: Text(
                '我的.预览'.tr(),
                style: TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建顶部完整度区域。
  Widget _buildCompletionSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Container(
        height: 88,
        padding: const EdgeInsets.fromLTRB(12, 15, 16, 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFE8F2FF), Colors.white],
            stops: <double>[0, 0.5],
          ),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 20,
              offset: Offset(0, 4),
              spreadRadius: -8,
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Image.asset(
              _ResumeEditorAssets.completionBadgeBg,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        '我的.简历完整度'.tr(),
                        style: TextStyle(
                          color: Color(0xFF262626),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 22 / 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_completionRate%',
                        style: const TextStyle(
                          color: Color(0xFF096DD9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 22 / 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Stack(
                      children: <Widget>[
                        Container(height: 6, color: const Color(0xFFE9EEF5)),
                        FractionallySizedBox(
                          widthFactor: _completionRate / 100,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1890FF),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '我的.完善简历提示'.tr(),
                    style: TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      height: 18 / 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建基础信息区域。
  Widget _buildBasicInfoSection() {
    final user = ref.watch(authSessionProvider).user;
    final _EditorBasicInfoViewData basicInfoViewData = _buildBasicInfoViewData(
      user,
    );
    final List<Widget> metaWidgets = <Widget>[
      if (basicInfoViewData.region.isNotEmpty)
        _buildMetaText(basicInfoViewData.region),
      if (basicInfoViewData.gender.isNotEmpty ||
          basicInfoViewData.age.isNotEmpty)
        _buildMetaText(
          [
            if (basicInfoViewData.gender.isNotEmpty) basicInfoViewData.gender,
            if (basicInfoViewData.age.isNotEmpty)
              '招聘.岁'.tr(namedArgs: {'count': basicInfoViewData.age}),
          ].join('·'),
        ),
      if (basicInfoViewData.phone.isNotEmpty)
        _buildMetaText(basicInfoViewData.phone),
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildSectionHeader(title: '我的.基础信息'.tr()),
                const SizedBox(height: 20),
                Text(
                  basicInfoViewData.name.isEmpty
                      ? '我的.未填写姓名'.tr()
                      : basicInfoViewData.name,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (metaWidgets.isEmpty)
                  _buildMetaText('我的.暂无基础信息'.tr())
                else
                  Wrap(spacing: 12, runSpacing: 6, children: metaWidgets),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: _openMyInfoPage,
                child: SvgPicture.asset(
                  _ResumeEditorAssets.basicInfoEdit,
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(height: 22),
              _buildProfileAvatar(basicInfoViewData),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建求职意向区域。
  Widget _buildJobIntentionSection() {
    final countrySearch = ref.watch(
      countrySearchProvider(const CountrySearchQuery()),
    );
    final Map<String, String> countryLabelMap = countrySearch.maybeWhen(
      data: (result) => buildCountryLabelMap(result.list),
      orElse: () => const <String, String>{},
    );
    final String currencyLabel = _selectedSalaryCurrency.labelKey.tr();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(title: '我的.求职意向'.tr(), showRedDot: true),
          const SizedBox(height: 20),
          _buildLabeledRow(
            label: '我的.期望职位'.tr(),
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openExpectedJobSheet,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _jobTags.isEmpty
                ? <Widget>[_buildEmptyStateChip('我的.暂无期望职位'.tr())]
                : _jobTags
                      .map(
                        (String item) => _buildTagChip(
                          label: item,
                          iconPath: _ResumeEditorAssets.tagRemove,
                          backgroundColor: const Color(0xFFEDF4FF),
                          textColor: const Color(0xFF096DD9),
                          onIconTap: () => _removeJobTag(item),
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 12),
          _buildTagChip(
            label: '我的.自定义'.tr(),
            iconPath: _ResumeEditorAssets.tagAdd,
            backgroundColor: const Color(0xFFF5F7FA),
            textColor: const Color(0xFF171A1D),
            borderColor: const Color(0xFFD9D9D9),
            onTap: _openCustomExpectedJobDialog,
          ),
          const SizedBox(height: 24),
          _buildLabeledRow(
            label: '我的.期望国家地区'.tr(),
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openExpectedCountrySheet,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _countryTags.isEmpty
                ? <Widget>[_buildEmptyStateChip('我的.暂无期望国家地区'.tr())]
                : _countryTags
                      .map(
                        (String item) => _buildTagChip(
                          label: resolveCountryLabel(item, countryLabelMap),
                          iconPath: _ResumeEditorAssets.tagRemove,
                          backgroundColor: const Color(0xFFEDF4FF),
                          textColor: const Color(0xFF096DD9),
                          onIconTap: () => _removeCountryTag(item),
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 24),
          _buildLabeledRow(
            label: '我的.期望薪资月'.tr(),
            trailing: FieldTrailingSelector(
              label: currencyLabel,
              onTap: _openSalaryCurrencySheet,
              textStyle: const TextStyle(
                color: Color(0xFF595959),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildSalaryInputField(
                  controller: _salaryValueController,
                  hintText: '我的.最低期望'.tr(),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '我的.至'.tr(),
                style: TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 18 / 13,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSalaryInputField(
                  controller: _salaryMaxValueController,
                  hintText: '我的.最高期望'.tr(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryInputField({
    required TextEditingController controller,
    required String hintText,
  }) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF171A1D),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 18 / 16,
        ),
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFBFBFBF),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 18 / 16,
          ),
        ),
      ),
    );
  }

  /// 构建工作经历区域。
  Widget _buildWorkExperienceSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            title: '我的.工作经历'.tr(),
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openAddWorkExperiencePage,
            ),
          ),
          const SizedBox(height: 20),
          if (_experiences.isEmpty)
            _buildEmptySectionText('我的.暂无工作经历'.tr())
          else
            for (
              int index = 0;
              index < _experiences.length;
              index++
            ) ...<Widget>[
              _buildExperienceItem(_experiences[index], index),
              if (index != _experiences.length - 1) const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  /// 构建语言能力区域。
  Widget _buildLanguageSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            title: '我的.语言能力'.tr(),
            trailing: _buildChevronActionIcon(onTap: _openLanguageSheet),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _languages.isEmpty
                ? <Widget>[_buildEmptySectionText('我的.暂无语言能力'.tr())]
                : _languages
                      .map(
                        (_ResumeLanguage item) => _buildTagChip(
                          label: item.displayLabel,
                          iconPath: _ResumeEditorAssets.languageTagRemove,
                          backgroundColor: const Color(0xFFEDF4FF),
                          textColor: const Color(0xFF096DD9),
                          onIconTap: () => _removeLanguageTag(item),
                        ),
                      )
                      .toList(),
          ),
        ],
      ),
    );
  }

  /// 构建技能证书区域。
  Widget _buildCertificateSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            title: '我的.技能证书'.tr(),
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openAddSkillCertificatePage,
            ),
          ),
          const SizedBox(height: 20),
          if (_certificates.isEmpty)
            _buildEmptySectionText('我的.暂无技能证书'.tr())
          else
            for (
              int index = 0;
              index < _certificates.length;
              index++
            ) ...<Widget>[
              _buildCertificateItem(_certificates[index], index),
              if (index != _certificates.length - 1) const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }

  Widget _buildCertificateItem(_ResumeCertificate certificate, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditSkillCertificatePage(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      certificate.title,
                      style: const TextStyle(
                        color: Color(0xFF262626),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 22 / 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      certificate.authority,
                      style: const TextStyle(
                        color: Color(0xFF595959),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: <Widget>[
                  Text(
                    certificate.issuedAt,
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 18 / 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Color(0xFFBFBFBF),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCertificatePreview(certificate),
        ],
      ),
    );
  }

  Widget _buildCertificatePreview(_ResumeCertificate certificate) {
    if (certificate.previewFilePaths.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: certificate.previewFilePaths
            .map(
              (String path) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 88,
                      height: 88,
                      color: const Color(0xFFF5F7FA),
                    );
                  },
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    if (certificate.previewImageUrls.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: certificate.previewImageUrls
            .map(
              (String url) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) {
                    return Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      color: const Color(0xFFF5F7FA),
                      child: Text(
                        '我的.加载失败'.tr(),
                        style: TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
            .toList(growable: false),
      );
    }

    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '我的.暂无图片'.tr(),
        style: TextStyle(
          color: Color(0xFF8C8C8C),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  /// 构建教育经历区域。
  Widget _buildEducationSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            title: '我的.教育经历'.tr(),
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openAddEducationExperiencePage,
            ),
          ),
          const SizedBox(height: 20),
          if (_educations.isEmpty)
            _buildEmptySectionText('我的.暂无教育经历'.tr())
          else
            for (
              int index = 0;
              index < _educations.length;
              index++
            ) ...<Widget>[
              _buildEducationItem(_educations[index], index),
              if (index != _educations.length - 1) const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(_ResumeEducation item, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditEducationExperiencePage(index),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Image.asset(
            _ResumeEditorAssets.educationLogo,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.school,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 22 / 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: <Widget>[
                Text(
                  item.period,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 18 / 13,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: Color(0xFFBFBFBF),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自我评价区域。
  Widget _buildSelfEvaluationSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(
            title: '我的.自我评价'.tr(),
            trailing: _buildChevronActionIcon(onTap: _openSelfEvaluationPage),
          ),
          const SizedBox(height: 14),
          if (_selfEvaluation.trim().isEmpty)
            _buildEmptySectionText('我的.暂无自我评价'.tr())
          else
            Text(
              _selfEvaluation,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF595959),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 22 / 14,
              ),
            ),
        ],
      ),
    );
  }

  /// 构建通用分组标题。
  Widget _buildSectionHeader({
    required String title,
    Widget? trailing,
    bool showRedDot = false,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF096DD9),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
        if (showRedDot) ...<Widget>[
          const SizedBox(width: 4),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4D4F),
              shape: BoxShape.circle,
            ),
          ),
        ],
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  /// 构建小标题行。
  Widget _buildLabeledRow({required String label, required Widget trailing}) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 22 / 14,
          ),
        ),
        const Spacer(),
        trailing,
      ],
    );
  }

  /// 构建基础信息里的灰色文案。
  Widget _buildMetaText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF595959),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 16 / 14,
      ),
    );
  }

  /// 构建区块为空时的统一提示文案。
  Widget _buildEmptySectionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF8C8C8C),
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
    );
  }

  /// 构建空状态标签，保持标签区域的视觉结构一致。
  Widget _buildEmptyStateChip(String text) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF8C8C8C),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 18 / 14,
        ),
      ),
    );
  }

  /// 构建基础信息区头像，优先展示接口返回的真实头像地址。
  Widget _buildProfileAvatar(_EditorBasicInfoViewData basicInfoViewData) {
    final String avatarUrl = basicInfoViewData.avatarUrl;
    if (_isNetworkPath(avatarUrl)) {
      return AppUserAvatar(
        imageUrl: avatarUrl,
        size: 48,
        placeholder: _buildAvatarPlaceholder(
          basicInfoViewData.avatarFallbackText,
        ),
      );
    }
    return _buildAvatarPlaceholder(basicInfoViewData.avatarFallbackText);
  }

  /// 接口未返回头像时展示统一占位头像。
  Widget _buildAvatarPlaceholder(String fallbackText) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFE9EEF5),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        fallbackText,
        style: const TextStyle(
          color: Color(0xFF8C8C8C),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _EditorBasicInfoViewData _buildBasicInfoViewData(dynamic user) {
    final String name = _draft.name.trim().isNotEmpty
        ? _draft.name.trim()
        : _readCurrentUserName(user);
    return _EditorBasicInfoViewData(
      name: name,
      region: _draft.region.trim().isNotEmpty
          ? _draft.region.trim()
          : _readCurrentUserRegion(user),
      age: _draft.age.trim().isNotEmpty
          ? _draft.age.trim()
          : _readCurrentUserAge(user),
      gender: _draft.gender.trim().isNotEmpty
          ? _draft.gender.trim()
          : _readCurrentUserGender(user),
      phone: _draft.phone.trim().isNotEmpty
          ? _draft.phone.trim()
          : _readCurrentUserPhone(user),
      avatarUrl: _readDraftAvatarUrl().isNotEmpty
          ? _readDraftAvatarUrl()
          : _readCurrentUserAvatarUrl(user),
      avatarFallbackText: _buildAvatarFallbackText(name),
    );
  }

  String _readCurrentUserName(dynamic user) {
    final String nickname = user?.nickname?.toString().trim() ?? '';
    return nickname;
  }

  String _readCurrentUserRegion(dynamic user) {
    return user?.currentLocation?.toString().trim() ?? '';
  }

  String _readCurrentUserPhone(dynamic user) {
    return user?.phone?.toString().trim() ?? '';
  }

  String _readCurrentUserAvatarUrl(dynamic user) {
    return user?.avatarUrl?.toString().trim() ?? '';
  }

  String _readCurrentUserGender(dynamic user) {
    final String value = user?.gender?.toString().trim().toLowerCase() ?? '';
    switch (value) {
      case 'male':
      case 'man':
      case 'm':
      case '1':
      case '男':
        return '我的.男'.tr();
      case 'female':
      case 'woman':
      case 'f':
      case '0':
      case '女':
        return '我的.女'.tr();
      default:
        return '';
    }
  }

  String _readCurrentUserAge(dynamic user) {
    final String birthday = user?.birthday?.toString().trim() ?? '';
    if (birthday.isEmpty) {
      return '';
    }
    final List<String> parts = birthday
        .replaceAll('.', '-')
        .replaceAll('/', '-')
        .split('-');
    if (parts.length < 3) {
      return '';
    }
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return '';
    }
    final DateTime now = DateTime.now();
    int age = now.year - year;
    if (now.month < month || (now.month == month && now.day < day)) {
      age -= 1;
    }
    return age > 0 ? age.toString() : '';
  }

  String _readDraftAvatarUrl() {
    return _resume?.basicInfo.avatarUrl.trim() ?? '';
  }

  String _buildAvatarFallbackText(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return '消息.我'.tr();
    }
    final List<int> runes = trimmed.runes.toList(growable: false);
    final int takeCount = runes.length >= 2 ? 2 : 1;
    return String.fromCharCodes(runes.take(takeCount));
  }

  /// 构建带图标的标签按钮。
  Widget _buildTagChip({
    required String label,
    required String iconPath,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
    VoidCallback? onTap,
    VoidCallback? onIconTap,
  }) {
    final Widget content = Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: borderColor == null ? null : Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (iconPath == _ResumeEditorAssets.tagAdd) ...<Widget>[
            SvgPicture.asset(iconPath, width: 10, height: 10),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 18 / 14,
            ),
          ),
          if (iconPath != _ResumeEditorAssets.tagAdd) ...<Widget>[
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onIconTap,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: SvgPicture.asset(iconPath, width: 8, height: 8),
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return content;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  /// 构建右侧操作图标，当前用于“添加”这类资源型按钮。
  Widget _buildActionIcon(String assetPath, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: assetPath.endsWith('.svg')
              ? SvgPicture.asset(assetPath, width: 20, height: 20)
              : Image.asset(assetPath, width: 20, height: 20),
        ),
      ),
    );
  }

  /// 构建统一的系统右箭头操作按钮，替代原有图片箭头资源。
  Widget _buildChevronActionIcon({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Color(0xFFBFBFBF),
          ),
        ),
      ),
    );
  }

  /// 构建单条工作经历内容。
  Widget _buildExperienceItem(_ResumeExperience item, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openEditWorkExperiencePage(index),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  item.company,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: <Widget>[
                    Text(
                      item.period,
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 18 / 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Color(0xFFBFBFBF),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item.roleLabel,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 22 / 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部固定操作区。
  Widget _buildBottomAction(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _saveResume,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF171A1D),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD9D9D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '我的.保存'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveAndPreview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF096DD9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '我的.提交并预览'.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 33),
        ],
      ),
    );
  }

  /// 打开我的信息页，并在返回后刷新基础信息展示。
  Future<void> _openMyInfoPage() async {
    await context.push<bool>(RoutePaths.myInfo);
  }

  /// 提交保存接口，并在成功后把结果回传上一页用于刷新。
  Future<void> _saveResume() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _persistResume();
      if (!mounted) {
        return;
      }
      _didSave = true;
      AppToast.show(_isCreateMode ? '我的.创建简历已保存'.tr() : '我的.简历修改已保存'.tr());
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      AppToast.show(_resolveSaveErrorMessage(error));
    }
  }

  /// 保存当前编辑内容后再进入预览页，避免预览与服务端数据不一致。
  Future<void> _saveAndPreview() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await _persistResume();
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      _didSave = true;
      _openPreview();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      AppToast.show(_resolveSaveErrorMessage(error));
    }
  }

  /// 按当前编辑目标保存简历；多简历场景优先走指定 `resumeId` 更新接口。
  Future<void> _persistResume() async {
    final SaveResumeBO request = _buildSaveRequest();
    final int? resumeId = _targetResumeId;
    final service = ref.read(resumeServiceProvider);
    if (resumeId != null && resumeId > 0) {
      await service.updateResume(resumeId: resumeId, request: request);
      return;
    }
    await service.saveResume(request: request);
  }

  /// 组装保存简历所需的全量请求。
  SaveResumeBO _buildSaveRequest() {
    final dynamic user = ref.read(authSessionProvider).user;
    final String currentLocation = _buildBasicInfoViewData(user).region;
    return SaveResumeBO(
      jobIntention: JobIntentionBO(
        positions: _jobTags,
        countries: _countryTags,
        salaryMin: _parseSalaryMin(),
        salaryMax: _parseSalaryMax(),
        salaryCurrency: _selectedSalaryCurrency.apiValue,
      ),
      workExperiences: _experiences
          .asMap()
          .entries
          .map(
            (entry) => WorkExperienceBO(
              expId: entry.value.expId,
              company: entry.value.company,
              department: entry.value.department,
              position: entry.value.position,
              startDate: entry.value.startDate,
              endDate: entry.value.endDate,
              isCurrent: entry.value.isCurrent,
              description: entry.value.summary,
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      languages: _languages
          .asMap()
          .entries
          .map(
            (entry) => LanguageAbilityBO(
              langId: entry.value.langId,
              language: entry.value.language,
              certificate: entry.value.certificate,
              level: entry.value.level,
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      skillCertificates: _certificates
          .asMap()
          .entries
          .map(
            (entry) => SkillCertificateBO(
              certId: entry.value.certId,
              name: entry.value.title,
              level: entry.value.level,
              issuer: entry.value.authority,
              issuedDate: entry.value.issuedAt,
              imageUrl: entry.value.previewFilePaths.isNotEmpty
                  ? entry.value.previewFilePaths.first
                  : entry.value.previewImageUrls.isNotEmpty
                  ? entry.value.previewImageUrls.first
                  : '',
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      educations: _educations
          .asMap()
          .entries
          .map(
            (entry) => EducationBO(
              eduId: entry.value.eduId,
              school: entry.value.school,
              major: entry.value.major,
              degree: entry.value.degree,
              startYear: entry.value.startYear,
              endYear: entry.value.endYear,
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      selfEvaluation: _selfEvaluation,
      isPublic: _draft.isPublic,
      completeness: 0,
      currentLocation: currentLocation,
    );
  }

  /// 统一提取保存失败提示。
  String _resolveSaveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '我的.简历保存失败'.tr();
  }

  /// 替换当前编辑页进入简历预览页，避免返回栈保留已提交的编辑页。
  void _openPreview() {
    context.pushReplacement(
      RoutePaths.resumePreview,
      extra: _buildPreviewArgs(),
    );
  }

  /// 组装预览页所需的真实数据快照，避免预览页再拼接任何假数据。
  ResumePreviewArgs _buildPreviewArgs() {
    return ResumePreviewArgs(
      draft: _currentDraft,
      avatarUrl: _resume?.basicInfo.avatarUrl ?? '',
      positions: List<String>.of(_jobTags),
      countries: List<String>.of(_countryTags),
      languages: _languages
          .map((item) => item.displayLabel)
          .toList(growable: false),
      experiences: _experiences
          .map(
            (item) => ResumePreviewExperience(
              company: item.company,
              period: item.period,
              role: item.roleLabel,
              summary: item.summary,
            ),
          )
          .toList(growable: false),
      certificates: _certificates
          .map(
            (item) => ResumePreviewCertificate(
              title: item.title,
              period: item.issuedAt,
              issuer: item.authority,
              localImagePaths: List<String>.of(item.previewFilePaths),
              networkImageUrls: List<String>.of(item.previewImageUrls),
            ),
          )
          .toList(growable: false),
      educations: _educations
          .map(
            (item) => ResumePreviewEducation(
              school: item.school,
              period: item.period,
              major: item.subtitle,
            ),
          )
          .toList(growable: false),
    );
  }

  ResumeDraft get _currentDraft {
    final _ResumeExperience? firstExperience = _experiences.isEmpty
        ? null
        : _experiences.first;

    return ResumeDraft(
      name: _draft.name,
      region: _draft.region,
      age: _draft.age,
      gender: _draft.gender,
      phone: _draft.phone,
      salary: _salaryMaxValue.isEmpty
          ? _salaryValue
          : '$_salaryValue-$_salaryMaxValue',
      salaryCurrency: _selectedSalaryCurrency.labelKey.tr(),
      jobTitle: firstExperience == null
          ? _draft.jobTitle
          : _buildDraftTitleFromExperience(firstExperience),
      duration: firstExperience?.period ?? _draft.duration,
      summary: _selfEvaluation,
      isPublic: _draft.isPublic,
    );
  }

  /// 提取保存请求使用的最低薪资。
  double _parseSalaryMin() {
    return _parseNumeric(_salaryValue);
  }

  /// 提取保存请求使用的最高薪资。
  double _parseSalaryMax() {
    return _parseNumeric(_salaryMaxValue);
  }

  double _parseNumeric(String text) {
    final String normalized = text
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  /// 从本地工作经历模型生成预览页使用的职位文案。
  String _buildDraftTitleFromExperience(_ResumeExperience experience) {
    final String role = experience.roleLabel;
    if (experience.company.isEmpty) {
      return role;
    }
    if (role.isEmpty) {
      return experience.company;
    }
    return '${experience.company}·$role';
  }

  /// 从证书名中尽量提取语言名称，证书原文仍保留到 certificate 字段。
  String _resolveLanguageName(String label) {
    if (label.contains('德')) {
      return '我的.德语'.tr();
    }
    if (label.contains('法')) {
      return '我的.法语'.tr();
    }
    if (label.contains('英')) {
      return '我的.英语'.tr();
    }
    if (label.contains('西班牙')) {
      return '我的.西班牙语'.tr();
    }
    return label;
  }

  Future<void> _openExpectedJobSheet() async {
    final List<SelectableSheetOption<String>> positionOptions;
    try {
      final categories = await ref.read(positionTreeProvider(null).future);
      positionOptions = _buildPositionSheetOptions(categories);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppToast.show('我的.职位字典加载失败'.tr());
      return;
    }

    if (positionOptions.isEmpty) {
      if (!mounted) {
        return;
      }
      AppToast.show('我的.暂无可选职位'.tr());
      return;
    }

    final Set<String> validValues = positionOptions
        .map((SelectableSheetOption<String> item) => item.value)
        .toSet();
    final List<String> currentSelected = _jobTags
        .where(validValues.contains)
        .toList(growable: false);

    if (!mounted) {
      return;
    }
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '我的.期望职位'.tr(),
      options: positionOptions,
      initialSelectedValues: currentSelected,
    );

    if (result == null) {
      return;
    }

    setState(() {
      _jobTags
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _openCustomExpectedJobDialog() async {
    final String? result = await showAppTextInputDialog(
      context: context,
      title: '我的.自定义期望职位标题'.tr(),
      hintText: '我的.自定义期望职位占位'.tr(),
    );
    if (!mounted || result == null) {
      return;
    }
    final String value = result.trim();
    if (value.isEmpty) {
      AppToast.show('我的.期望职位不能为空'.tr());
      return;
    }
    if (_jobTags.contains(value)) {
      AppToast.show('我的.期望职位已存在'.tr());
      return;
    }
    setState(() {
      _jobTags.add(value);
    });
  }

  List<SelectableSheetOption<String>> _buildPositionSheetOptions(
    List<PositionCategoryVO> categories,
  ) {
    final Set<String> seen = <String>{};
    final List<SelectableSheetOption<String>> result =
        <SelectableSheetOption<String>>[];
    for (final PositionCategoryVO item in categories) {
      for (final PositionVO position in item.positions) {
        final String value = position.nameZh.trim();
        if (value.isEmpty || !seen.add(value)) {
          continue;
        }
        result.add(SelectableSheetOption<String>(value: value, label: value));
      }
    }
    return result;
  }

  Future<List<SelectableSheetOption<String>>>
  _loadLanguageSheetOptions() async {
    final List<TagItemVO> tags = await ref.read(
      tagDictionaryProvider(TagCategory.languageCert).future,
    );
    return tags
        .map((TagItemVO item) {
          final String label = item.tagNameZh.trim().isNotEmpty
              ? item.tagNameZh.trim()
              : item.tagCode.trim();
          return SelectableSheetOption<String>(value: label, label: label);
        })
        .toList(growable: false);
  }

  Future<void> _openExpectedCountrySheet() async {
    final List<CountryVO>? result = await showCountryOptionsBottomSheet(
      context: context,
      ref: ref,
      title: '我的.期望国家地区'.tr(),
      initialSelectedValues: _countryTags,
    );
    if (!mounted || result == null) {
      return;
    }
    setState(() {
      _countryTags
        ..clear()
        ..addAll(result.map((CountryVO item) => item.countryCode.trim()));
    });
  }

  Future<void> _openSalaryCurrencySheet() async {
    final AppCurrency? result = await showAppCurrencyOptionsBottomSheet(
      context: context,
      initialValue: _selectedSalaryCurrency,
    );
    if (!mounted || result == null || result == _selectedSalaryCurrency) {
      return;
    }
    setState(() {
      _selectedSalaryCurrency = result;
    });
  }

  void _removeJobTag(String value) {
    setState(() {
      _jobTags.remove(value);
    });
  }

  void _removeCountryTag(String value) {
    setState(() {
      _countryTags.remove(value);
    });
  }

  void _removeLanguageTag(_ResumeLanguage value) {
    setState(() {
      _languages.remove(value);
    });
  }

  Future<void> _openLanguageSheet() async {
    final List<SelectableSheetOption<String>> languageOptions;
    try {
      languageOptions = await _loadLanguageSheetOptions();
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppToast.show('我的.语言字典加载失败'.tr());
      return;
    }
    if (languageOptions.isEmpty) {
      if (!mounted) {
        return;
      }
      AppToast.show('我的.暂无可选语言能力'.tr());
      return;
    }
    if (!mounted) {
      return;
    }
    final Map<String, _ResumeLanguage> existingByLabel =
        <String, _ResumeLanguage>{
          for (final _ResumeLanguage item in _languages)
            item.displayLabel: item,
        };
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '我的.语言能力'.tr(),
      options: languageOptions,
      initialSelectedValues: _languages
          .map((item) => item.displayLabel)
          .toList(growable: false),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _languages
        ..clear()
        ..addAll(
          result.map(
            (String value) =>
                existingByLabel[value] ??
                _ResumeLanguage(
                  langId: 0,
                  language: _resolveLanguageName(value),
                  certificate: value,
                  level: '',
                ),
          ),
        );
    });
  }

  Future<void> _openAddSkillCertificatePage() async {
    final ResumeCertificatePageResult? result = await context
        .push<ResumeCertificatePageResult>(
          RoutePaths.addSkillCertificate,
          extra: const AddSkillCertificatePageArgs(),
        );

    if (result == null || result.value == null) {
      return;
    }

    setState(() {
      _certificates.insert(
        0,
        _buildResumeCertificateFromFormResult(result.value!),
      );
    });
  }

  Future<void> _openEditSkillCertificatePage(int index) async {
    final _ResumeCertificate current = _certificates[index];
    final ResumeCertificatePageResult? result = await context
        .push<ResumeCertificatePageResult>(
          RoutePaths.addSkillCertificate,
          extra: AddSkillCertificatePageArgs(
            initialValue: _buildCertificateFormResult(current),
          ),
        );

    if (result == null) {
      return;
    }

    setState(() {
      if (result.deleted) {
        _certificates.removeAt(index);
        return;
      }
      if (result.value == null) {
        return;
      }
      _certificates[index] = _buildResumeCertificateFromFormResult(
        result.value!,
        certId: current.certId,
        authority: current.authority,
        level: current.level,
      );
    });
  }

  Future<void> _openSelfEvaluationPage() async {
    final String? result = await context.push<String>(
      RoutePaths.selfEvaluation,
      extra: _selfEvaluation,
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selfEvaluation = result;
    });
  }

  Future<void> _openAddEducationExperiencePage() async {
    final EducationExperiencePageResult? result = await context
        .push<EducationExperiencePageResult>(
          RoutePaths.addEducationExperience,
          extra: const AddEducationExperiencePageArgs(),
        );

    if (result == null || result.value == null) {
      return;
    }

    setState(() {
      _educations.insert(0, _buildResumeEducationFromFormResult(result.value!));
    });
  }

  Future<void> _openEditEducationExperiencePage(int index) async {
    final _ResumeEducation current = _educations[index];
    final EducationExperiencePageResult? result = await context
        .push<EducationExperiencePageResult>(
          RoutePaths.addEducationExperience,
          extra: AddEducationExperiencePageArgs(
            initialValue: _buildEducationFormResult(current),
          ),
        );

    if (result == null) {
      return;
    }

    setState(() {
      if (result.deleted) {
        _educations.removeAt(index);
        return;
      }
      if (result.value == null) {
        return;
      }
      _educations[index] = _buildResumeEducationFromFormResult(
        result.value!,
        eduId: current.eduId,
      );
    });
  }

  Future<void> _openAddWorkExperiencePage() async {
    final WorkExperiencePageResult? result = await context
        .push<WorkExperiencePageResult>(
          RoutePaths.addWorkExperience,
          extra: const AddWorkExperiencePageArgs(),
        );

    if (result == null || result.value == null) {
      return;
    }

    setState(() {
      _experiences.insert(
        0,
        _buildResumeExperienceFromFormResult(result.value!),
      );
    });
  }

  Future<void> _openEditWorkExperiencePage(int index) async {
    final _ResumeExperience current = _experiences[index];
    final WorkExperiencePageResult? result = await context
        .push<WorkExperiencePageResult>(
          RoutePaths.addWorkExperience,
          extra: AddWorkExperiencePageArgs(
            initialValue: _buildWorkExperienceFormResult(current),
          ),
        );

    if (result == null) {
      return;
    }

    setState(() {
      if (result.deleted) {
        _experiences.removeAt(index);
        return;
      }
      if (result.value == null) {
        return;
      }
      _experiences[index] = _buildResumeExperienceFromFormResult(
        result.value!,
        expId: current.expId,
      );
    });
  }

  ResumeCertificateFormResult _buildCertificateFormResult(
    _ResumeCertificate item,
  ) {
    return ResumeCertificateFormResult(
      title: item.title,
      issuedAt: _parseSingleMonth(item.issuedAt),
      localImagePaths: List<String>.of(item.previewFilePaths),
      networkImageUrls: List<String>.of(item.previewImageUrls),
    );
  }

  _ResumeCertificate _buildResumeCertificateFromFormResult(
    ResumeCertificateFormResult result, {
    int certId = 0,
    String authority = '',
    String level = '',
  }) {
    return _ResumeCertificate(
      certId: certId,
      title: result.title,
      level: level,
      authority: authority.isEmpty ? '我的.技能证书'.tr() : authority,
      issuedAt: result.issuedAt.format(ResumeTimePickerType.singleMonth),
      previewFilePaths: List<String>.of(result.localImagePaths),
      previewImageUrls: List<String>.of(result.networkImageUrls),
    );
  }

  EducationExperienceFormResult _buildEducationFormResult(
    _ResumeEducation item,
  ) {
    return EducationExperienceFormResult(
      school: item.school,
      degree: item.degree,
      major: item.major,
      period: ResumeTimePickerValue(
        startYear: item.startYear,
        startMonth: 1,
        endYear: item.endYear <= 0 ? null : item.endYear,
        endMonth: item.endYear <= 0 ? null : 12,
      ),
    );
  }

  _ResumeEducation _buildResumeEducationFromFormResult(
    EducationExperienceFormResult result, {
    int eduId = 0,
  }) {
    return _ResumeEducation(
      eduId: eduId,
      school: result.school,
      major: result.major,
      degree: result.degree,
      startYear: result.period.startYear,
      endYear: result.period.endYear ?? 0,
    );
  }

  WorkExperienceFormResult _buildWorkExperienceFormResult(
    _ResumeExperience item,
  ) {
    return WorkExperienceFormResult(
      company: item.company,
      period: _buildEmploymentPeriodValue(item),
      jobTitle: item.position,
      department: item.department,
      description: item.summary == '我的.未填写工作内容'.tr() ? '' : item.summary,
    );
  }

  _ResumeExperience _buildResumeExperienceFromFormResult(
    WorkExperienceFormResult result, {
    int expId = 0,
  }) {
    return _ResumeExperience(
      expId: expId,
      company: result.company,
      department: result.department,
      position: result.jobTitle,
      startDate: _formatYearMonth(
        result.period.startYear,
        result.period.startMonth,
      ),
      endDate: result.period.isCurrent
          ? ''
          : _formatYearMonth(
              result.period.endYear ?? result.period.startYear,
              result.period.endMonth ?? result.period.startMonth,
            ),
      isCurrent: result.period.isCurrent,
      summary: result.description.isEmpty
          ? '我的.未填写工作内容'.tr()
          : result.description,
    );
  }

  EmploymentPeriodValue _buildEmploymentPeriodValue(_ResumeExperience item) {
    final List<int> start = _parseYearMonth(item.startDate);
    final List<int>? end = item.isCurrent
        ? null
        : _tryParseYearMonth(item.endDate);
    return EmploymentPeriodValue(
      startYear: start[0],
      startMonth: start[1],
      endYear: end?[0],
      endMonth: end?[1],
    ).normalized();
  }

  ResumeTimePickerValue _parseSingleMonth(String value) {
    final List<int> parts = _parseYearMonth(value);
    return ResumeTimePickerValue(
      startYear: parts[0],
      startMonth: parts[1],
      endYear: parts[0],
      endMonth: parts[1],
    );
  }

  List<int> _parseYearMonth(String value) {
    return _tryParseYearMonth(value) ?? <int>[DateTime.now().year, 1];
  }

  List<int>? _tryParseYearMonth(String value) {
    final RegExpMatch? match = RegExp(
      r'^(\d{4})[.-](\d{1,2})$',
    ).firstMatch(value.trim());
    if (match == null) {
      return null;
    }
    return <int>[int.parse(match.group(1)!), int.parse(match.group(2)!)];
  }

  /// 将年月组装成接口文档要求的 `yyyy-MM` 字符串。
  String _formatYearMonth(int year, int month) {
    return '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
  }
}

/// 编辑页资源路径。
class _ResumeEditorAssets {
  static const String completionBadgeBg =
      'assets/images/completion_badge_bg.png';
  static const String basicInfoEdit = 'assets/images/basic_info_edit.svg';
  static const String addCircle = 'assets/images/add_circle.svg';
  static const String tagRemove = 'assets/images/tag_remove.svg';
  static const String tagAdd = 'assets/images/tag_add.svg';
  static const String languageTagRemove =
      'assets/images/language_tag_remove.svg';
  static const String educationLogo = 'assets/images/education_logo.png';
}

/// 工作经历展示模型。
class _ResumeExperience {
  const _ResumeExperience({
    required this.expId,
    required this.company,
    required this.department,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.summary,
  });

  final int expId;
  final String company;
  final String department;
  final String position;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final String summary;

  /// 工作经历展示时优先拼接“部门·职位”结构。
  String get roleLabel {
    if (department.isEmpty) {
      return position;
    }
    if (position.isEmpty) {
      return department;
    }
    return '$department·$position';
  }

  /// 工作经历展示时统一输出时间段文案。
  String get period {
    if (startDate.isEmpty && endDate.isEmpty) {
      return '';
    }
    if (isCurrent) {
      final String currentLabel = '我的.至今'.tr();
      return startDate.isEmpty ? currentLabel : '$startDate - $currentLabel';
    }
    if (startDate.isEmpty) {
      return endDate;
    }
    if (endDate.isEmpty) {
      return startDate;
    }
    return '$startDate - $endDate';
  }
}

/// 语言能力展示模型。
class _ResumeLanguage {
  const _ResumeLanguage({
    required this.langId,
    required this.language,
    required this.certificate,
    required this.level,
  });

  final int langId;
  final String language;
  final String certificate;
  final String level;

  /// 标签展示优先使用证书名，缺失时回退到语言名。
  String get displayLabel {
    return certificate.isEmpty ? language : certificate;
  }
}

/// 技能证书展示模型。
class _ResumeCertificate {
  const _ResumeCertificate({
    required this.certId,
    required this.title,
    required this.level,
    required this.authority,
    required this.issuedAt,
    this.previewFilePaths = const <String>[],
    this.previewImageUrls = const <String>[],
  });

  final int certId;
  final String title;
  final String level;
  final String authority;
  final String issuedAt;
  final List<String> previewFilePaths;
  final List<String> previewImageUrls;
}

/// 教育经历展示模型。
class _ResumeEducation {
  const _ResumeEducation({
    required this.eduId,
    required this.school,
    required this.major,
    required this.degree,
    required this.startYear,
    required this.endYear,
  });

  final int eduId;
  final String school;
  final String major;
  final String degree;
  final int startYear;
  final int endYear;

  /// 教育经历副标题展示专业与学历。
  String get subtitle {
    if (major.isEmpty) {
      return degree;
    }
    if (degree.isEmpty) {
      return major;
    }
    return '$major · $degree';
  }

  /// 教育经历展示年份区间。
  String get period {
    if (startYear <= 0 && endYear <= 0) {
      return '';
    }
    if (endYear <= 0) {
      return '$startYear - ${'我的.至今'.tr()}';
    }
    return '$startYear - $endYear';
  }
}
