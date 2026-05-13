import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../data/resume_models.dart';
import '../data/resume_providers.dart';
import 'add_education_experience_page.dart';
import 'add_skill_certificate_page.dart';
import 'add_work_experience_page.dart';
import '../../../shared/widgets/resume_time_picker_bottom_sheet.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';

/// 编辑页的进入模式。
enum ResumeEditorMode { create, edit }

/// 简历编辑页的路由参数。
class ResumeEditorArgs {
  const ResumeEditorArgs.create({this.isPublic = true})
    : mode = ResumeEditorMode.create,
      resume = null;

  ResumeEditorArgs.edit(this.resume)
    : mode = ResumeEditorMode.edit,
      isPublic = resume?.isPublic ?? true;

  final ResumeEditorMode mode;
  final ResumeVO? resume;
  final bool isPublic;
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
  static const List<String> _expectedJobOptions = <String>[
    '中餐厨师',
    '中餐面点',
    '高级电工',
    '护理员',
    '中级电工',
    '中餐主厨',
  ];
  static const List<SelectableSheetOption<String>> _expectedJobSheetOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: '中餐厨师', label: '中餐厨师'),
        SelectableSheetOption<String>(value: '中餐面点', label: '中餐面点'),
        SelectableSheetOption<String>(value: '高级电工', label: '高级电工'),
        SelectableSheetOption<String>(value: '护理员', label: '护理员'),
        SelectableSheetOption<String>(value: '中级电工', label: '中级电工'),
        SelectableSheetOption<String>(value: '中餐主厨', label: '中餐主厨'),
      ];

  static const List<SelectableSheetOption<String>> _countrySheetOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: '德国', label: '德国'),
        SelectableSheetOption<String>(value: '法国', label: '法国'),
        SelectableSheetOption<String>(value: '瑞士', label: '瑞士'),
        SelectableSheetOption<String>(value: '英国', label: '英国'),
        SelectableSheetOption<String>(value: '意大利', label: '意大利'),
        SelectableSheetOption<String>(value: '西班牙', label: '西班牙'),
      ];
  static const List<SelectableSheetOption<String>> _languageSheetOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: '德福TestDaF', label: '德福TestDaF'),
        SelectableSheetOption<String>(value: '法语专业四级', label: '法语专业四级'),
        SelectableSheetOption<String>(value: '英语专业四级', label: '英语专业四级'),
        SelectableSheetOption<String>(value: '英语专业八级', label: '英语专业八级'),
        SelectableSheetOption<String>(value: '歌德C2', label: '歌德C2'),
        SelectableSheetOption<String>(value: '西班牙语三级', label: '西班牙语三级'),
      ];

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
  bool _isSaving = false;
  bool _didSave = false;

  /// 当前页面是否为创建模式。
  bool get _isCreateMode => widget.args.mode == ResumeEditorMode.create;

  String get _salaryValue => _salaryValueController.text.trim();

  String get _salaryMaxValue => _salaryMaxValueController.text.trim();

  /// 当前页面展示服务端返回的简历完整度，创建模式默认 0。
  int get _completionRate {
    final int value = _resume?.completeness ?? 0;
    if (value < 0) {
      return 0;
    }
    if (value > 100) {
      return 100;
    }
    return value;
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
  }

  @override
  void dispose() {
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
      return startDate.isEmpty ? '至今' : '$startDate - 至今';
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
      title: const Text(
        '我的简历',
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
              child: const Text(
                '预览',
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
                      const Text(
                        '简历完整度',
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
                  const SizedBox(height: 4),
                  const Text(
                    '完善简历可以提高 50% 的匹配成功率',
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
    final List<Widget> metaWidgets = <Widget>[
      if (_draft.region.trim().isNotEmpty) _buildMetaText(_draft.region),
      if (_draft.gender.trim().isNotEmpty || _draft.age.trim().isNotEmpty)
        _buildMetaText(
          [
            if (_draft.gender.trim().isNotEmpty) _draft.gender.trim(),
            if (_draft.age.trim().isNotEmpty) '${_draft.age.trim()}岁',
          ].join('·'),
        ),
      if (_draft.phone.trim().isNotEmpty) _buildMetaText(_draft.phone),
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
                _buildSectionHeader(title: '基础信息'),
                const SizedBox(height: 20),
                Text(
                  _draft.name.isEmpty ? '未填写姓名' : _draft.name,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
                const SizedBox(height: 10),
                if (metaWidgets.isEmpty)
                  _buildMetaText('暂无基础信息')
                else
                  Wrap(spacing: 12, runSpacing: 6, children: metaWidgets),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: <Widget>[
              GestureDetector(
                onTap: _showComingSoon,
                child: SvgPicture.asset(
                  _ResumeEditorAssets.basicInfoEdit,
                  width: 20,
                  height: 20,
                ),
              ),
              const SizedBox(height: 22),
              _buildProfileAvatar(),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建求职意向区域。
  Widget _buildJobIntentionSection() {
    final String currencyLabel = _draft.salaryCurrency.trim().isEmpty
        ? '币种未设置'
        : _draft.salaryCurrency;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionHeader(title: '求职意向', showRedDot: true),
          const SizedBox(height: 20),
          _buildLabeledRow(
            label: '期望职位',
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
                ? <Widget>[_buildEmptyStateChip('暂无期望职位')]
                : _jobTags
                      .map(
                        (String item) => _buildTagChip(
                          label: item,
                          iconPath: _ResumeEditorAssets.tagRemove,
                          backgroundColor: const Color(0xFFEDF4FF),
                          textColor: const Color(0xFF096DD9),
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 12),
          _buildTagChip(
            label: '自定义',
            iconPath: _ResumeEditorAssets.tagAdd,
            backgroundColor: const Color(0xFFF5F7FA),
            textColor: const Color(0xFF171A1D),
            borderColor: const Color(0xFFD9D9D9),
          ),
          const SizedBox(height: 24),
          _buildLabeledRow(
            label: '期望国家/地区',
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
                ? <Widget>[_buildEmptyStateChip('暂无期望国家/地区')]
                : _countryTags
                      .map(
                        (String item) => _buildTagChip(
                          label: item,
                          iconPath: _ResumeEditorAssets.tagRemove,
                          backgroundColor: const Color(0xFFEDF4FF),
                          textColor: const Color(0xFF096DD9),
                        ),
                      )
                      .toList(),
          ),
          const SizedBox(height: 24),
          _buildLabeledRow(
            label: '期望薪资 (月)',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  currencyLabel,
                  style: const TextStyle(
                    color: Color(0xFF595959),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 22 / 14,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  _ResumeEditorAssets.dropdownArrow,
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildSalaryInputField(
                  controller: _salaryValueController,
                  hintText: '最低期望',
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '至',
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
                  hintText: '最高期望',
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
            title: '工作经历',
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openAddWorkExperiencePage,
            ),
          ),
          const SizedBox(height: 20),
          if (_experiences.isEmpty)
            _buildEmptySectionText('暂无工作经历')
          else
            for (
              int index = 0;
              index < _experiences.length;
              index++
            ) ...<Widget>[
              _buildExperienceItem(_experiences[index]),
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
            title: '语言能力',
            trailing: _buildChevronActionIcon(onTap: _openLanguageSheet),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: _languages.isEmpty
                ? <Widget>[_buildEmptySectionText('暂无语言能力')]
                : _languages
                      .map(
                        (_ResumeLanguage item) => _buildTagChip(
                          label: item.displayLabel,
                          iconPath: _ResumeEditorAssets.languageTagRemove,
                          backgroundColor: const Color(0xFFEDF4FF),
                          textColor: const Color(0xFF096DD9),
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
            title: '技能证书',
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openAddSkillCertificatePage,
            ),
          ),
          const SizedBox(height: 20),
          if (_certificates.isEmpty)
            _buildEmptySectionText('暂无技能证书')
          else
            for (
              int index = 0;
              index < _certificates.length;
              index++
            ) ...<Widget>[
              _buildCertificateItem(_certificates[index]),
              if (index != _certificates.length - 1) const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }

  Widget _buildCertificateItem(_ResumeCertificate certificate) {
    return Column(
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
                child: Image.network(
                  url,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 88,
                      height: 88,
                      alignment: Alignment.center,
                      color: const Color(0xFFF5F7FA),
                      child: const Text(
                        '加载失败',
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
      child: const Text(
        '暂无图片',
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
            title: '教育经历',
            trailing: _buildActionIcon(
              _ResumeEditorAssets.addCircle,
              onTap: _openAddEducationExperiencePage,
            ),
          ),
          const SizedBox(height: 20),
          if (_educations.isEmpty)
            _buildEmptySectionText('暂无教育经历')
          else
            for (
              int index = 0;
              index < _educations.length;
              index++
            ) ...<Widget>[
              _buildEducationItem(_educations[index]),
              if (index != _educations.length - 1) const SizedBox(height: 20),
            ],
        ],
      ),
    );
  }

  Widget _buildEducationItem(_ResumeEducation item) {
    return Row(
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
            title: '自我评价',
            trailing: _buildChevronActionIcon(onTap: _openSelfEvaluationPage),
          ),
          const SizedBox(height: 14),
          if (_selfEvaluation.trim().isEmpty)
            _buildEmptySectionText('暂无自我评价')
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
  Widget _buildProfileAvatar() {
    final String avatarUrl = _resume?.basicInfo.avatarUrl ?? '';
    if (_isNetworkPath(avatarUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.network(
          avatarUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
        ),
      );
    }
    return _buildAvatarPlaceholder();
  }

  /// 接口未返回头像时展示统一占位头像。
  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFE9EEF5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, size: 24, color: Color(0xFF8C8C8C)),
    );
  }

  /// 构建带图标的标签按钮。
  Widget _buildTagChip({
    required String label,
    required String iconPath,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
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
            SvgPicture.asset(iconPath, width: 8, height: 8),
          ],
        ],
      ),
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
  Widget _buildExperienceItem(_ResumeExperience item) {
    return Column(
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
                    child: const Text(
                      '保存',
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
                    child: const Text(
                      '提交并预览',
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

  /// 统一处理尚未接真实交互的点击反馈。
  void _showComingSoon() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('编辑功能开发中')));
  }

  /// 提交保存接口，并在成功后把结果回传上一页用于刷新。
  Future<void> _saveResume() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(resumeServiceProvider)
          .saveResume(request: _buildSaveRequest());
      if (!mounted) {
        return;
      }
      _didSave = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isCreateMode ? '创建简历已保存' : '简历修改已保存')),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveSaveErrorMessage(error))));
    }
  }

  /// 保存当前编辑内容后再进入预览页，避免预览与服务端数据不一致。
  Future<void> _saveAndPreview() async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(resumeServiceProvider)
          .saveResume(request: _buildSaveRequest());
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveSaveErrorMessage(error))));
    }
  }

  /// 组装保存简历所需的全量请求。
  SaveResumeBO _buildSaveRequest() {
    return SaveResumeBO(
      jobIntention: JobIntentionBO(
        positions: _jobTags,
        countries: _countryTags,
        salaryMin: _parseSalaryMin(),
        salaryMax: _parseSalaryMax(),
        salaryCurrency: _draft.salaryCurrency,
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
    );
  }

  /// 统一提取保存失败提示。
  String _resolveSaveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '简历保存失败，请稍后重试';
  }

  /// 跳转到简历预览页，并把当前编辑中的真实快照一并传递过去。
  void _openPreview() {
    context.push(RoutePaths.myResumePreview, extra: _buildPreviewArgs());
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
      salaryCurrency: _draft.salaryCurrency,
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
      return '德语';
    }
    if (label.contains('法')) {
      return '法语';
    }
    if (label.contains('英')) {
      return '英语';
    }
    if (label.contains('西班牙')) {
      return '西班牙语';
    }
    return label;
  }

  Future<void> _openExpectedJobSheet() async {
    final List<String> currentSelected = _jobTags
        .where(_expectedJobOptions.contains)
        .toList(growable: false);

    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '期望职位',
      options: _expectedJobSheetOptions,
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

  Future<void> _openExpectedCountrySheet() async {
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '期望国家/地区',
      options: _countrySheetOptions,
      initialSelectedValues: _countryTags,
    );

    if (result == null) {
      return;
    }

    setState(() {
      _countryTags
        ..clear()
        ..addAll(result);
    });
  }

  Future<void> _openLanguageSheet() async {
    final Map<String, _ResumeLanguage> existingByLabel =
        <String, _ResumeLanguage>{
          for (final _ResumeLanguage item in _languages)
            item.displayLabel: item,
        };
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '语言能力',
      options: _languageSheetOptions,
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
    final ResumeCertificateFormResult? result = await context
        .push<ResumeCertificateFormResult>(RoutePaths.addSkillCertificate);

    if (result == null) {
      return;
    }

    setState(() {
      _certificates.insert(
        0,
        _ResumeCertificate(
          certId: 0,
          title: result.title,
          level: '',
          authority: '技能证书',
          issuedAt: result.issuedAt.format(ResumeTimePickerType.singleMonth),
          previewFilePaths: result.imagePaths,
        ),
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
    final EducationExperienceFormResult? result = await context
        .push<EducationExperienceFormResult>(RoutePaths.addEducationExperience);

    if (result == null) {
      return;
    }

    setState(() {
      _educations.insert(
        0,
        _ResumeEducation(
          eduId: 0,
          school: result.school,
          major: result.major,
          degree: result.degree,
          startYear: result.period.startYear,
          endYear: result.period.endYear ?? 0,
        ),
      );
    });
  }

  Future<void> _openAddWorkExperiencePage() async {
    final WorkExperienceFormResult? result = await context
        .push<WorkExperienceFormResult>(RoutePaths.addWorkExperience);

    if (result == null) {
      return;
    }

    setState(() {
      _experiences.insert(
        0,
        _ResumeExperience(
          expId: 0,
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
          summary: result.description.isEmpty ? '未填写工作内容' : result.description,
        ),
      );
    });
  }

  /// 将年月组装成接口兼容的 `yyyy.MM` 字符串。
  String _formatYearMonth(int year, int month) {
    return '${year.toString().padLeft(4, '0')}.${month.toString().padLeft(2, '0')}';
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
  static const String dropdownArrow = 'assets/images/dropdown_arrow.png';
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
      return startDate.isEmpty ? '至今' : '$startDate - 至今';
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
      return '$startYear - 至今';
    }
    return '$startYear - $endYear';
  }
}
