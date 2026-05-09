import 'dart:io';

import 'package:flutter/material.dart';
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
      draft = null;

  ResumeEditorArgs.edit(this.draft)
    : mode = ResumeEditorMode.edit,
      isPublic = draft?.isPublic ?? true;

  final ResumeEditorMode mode;
  final ResumeDraft? draft;
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

/// 我的简历编辑页。
class MyResumeEditorPage extends ConsumerStatefulWidget {
  const MyResumeEditorPage({super.key, required this.args});

  final ResumeEditorArgs args;

  @override
  ConsumerState<MyResumeEditorPage> createState() => _MyResumeEditorPageState();
}

class _MyResumeEditorPageState extends ConsumerState<MyResumeEditorPage> {
  static const ResumeDraft _demoDraft = ResumeDraft(
    name: '程先生',
    region: '德国',
    age: '32',
    gender: '男',
    phone: '189****8655',
    salary: '1,500',
    jobTitle: '伦敦康诺特酒店·高级电工',
    duration: '2024.11 - 至今',
    summary:
        '本人从事餐饮烹饪工作多年，具备扎实的烹调功底，熟练掌握煎、炒、烹、炸、蒸等各类烹饪技法，擅长各类中餐菜品制作，能精准把控火候与口味，注重菜品营养搭配，能精准把控火候与口味，注重菜品营养搭配。',
  );

  static const List<_ResumeExperience> _fallbackExperiences =
      <_ResumeExperience>[
        _ResumeExperience(
          company: '香港文华东方酒店',
          period: '2020.09 - 2024.11',
          role: '餐饮部·高级厨师',
          summary:
              '责菜品制作与出品把控，熟练掌握各类烹饪技法与风味呈现，协助厨师长进行菜品研发与摆盘优化，严格遵守后厨卫生标准与流程...',
        ),
      ];
  static const List<_ResumeCertificate> _fallbackCertificates =
      <_ResumeCertificate>[
        _ResumeCertificate(
          title: '中式烹调师·五级',
          authority: '人力资源社会保障部',
          issuedAt: '2016.10',
          previewAssetPath: _ResumeEditorAssets.certificatePreview,
        ),
      ];
  static const List<_ResumeEducation> _fallbackEducations =
      <_ResumeEducation>[
        _ResumeEducation(
          school: '扬州大学',
          subtitle: '烹饪与营养教育',
          period: '2010 - 2013',
        ),
      ];

  static const List<String> _fallbackJobTags = <String>['中餐厨师', '中餐面点', '高级电工'];
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

  static const List<String> _fallbackCountryTags = <String>['德国', '法国', '意大利'];
  static const List<SelectableSheetOption<String>> _countrySheetOptions =
      <SelectableSheetOption<String>>[
        SelectableSheetOption<String>(value: '德国', label: '德国'),
        SelectableSheetOption<String>(value: '法国', label: '法国'),
        SelectableSheetOption<String>(value: '瑞士', label: '瑞士'),
        SelectableSheetOption<String>(value: '英国', label: '英国'),
        SelectableSheetOption<String>(value: '意大利', label: '意大利'),
        SelectableSheetOption<String>(value: '西班牙', label: '西班牙'),
      ];
  static const List<String> _fallbackLanguageTags = <String>[
    '德福TestDaF',
    '法语专业四级',
    '歌德C2',
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

  late final ResumeDraft _draft;
  late final List<String> _jobTags;
  late final List<String> _countryTags;
  late final List<String> _languageTags;
  late final List<_ResumeExperience> _experiences;
  late final List<_ResumeCertificate> _certificates;
  late final List<_ResumeEducation> _educations;
  late final String _salaryValue;
  late String _selfEvaluation;
  bool _isSaving = false;
  bool _didSave = false;

  /// 当前页面是否为创建模式。
  bool get _isCreateMode => widget.args.mode == ResumeEditorMode.create;

  /// 当前页面按设计稿固定展示 85% 完整度。
  int get _completionRate => 85;

  @override
  void initState() {
    super.initState();
    _draft = _resolveDraft(widget.args.draft);
    _jobTags = _buildJobTags(_draft.jobTitle);
    _countryTags = _buildCountryTags(_draft.region);
    _languageTags = List<String>.of(_fallbackLanguageTags);
    _experiences = _buildExperiences();
    _certificates = List<_ResumeCertificate>.of(_fallbackCertificates);
    _educations = List<_ResumeEducation>.of(_fallbackEducations);
    _salaryValue = _extractSalaryValue(_draft.salary);
    _selfEvaluation = _draft.summary.isEmpty
        ? _demoDraft.summary
        : _draft.summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: ListView(
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
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  /// 用草稿值覆盖设计稿默认值，保证创建和编辑模式都有完整布局。
  ResumeDraft _resolveDraft(ResumeDraft? draft) {
    final ResumeDraft source = draft ?? const ResumeDraft();
    return ResumeDraft(
      name: source.name.isEmpty ? _demoDraft.name : source.name,
      region: source.region.isEmpty ? _demoDraft.region : source.region,
      age: source.age.isEmpty ? _demoDraft.age : source.age,
      gender: source.gender.isEmpty ? _demoDraft.gender : source.gender,
      phone: source.phone.isEmpty ? _demoDraft.phone : source.phone,
      salary: source.salary.isEmpty ? _demoDraft.salary : source.salary,
      salaryCurrency: source.salaryCurrency.isEmpty
          ? _demoDraft.salaryCurrency
          : source.salaryCurrency,
      jobTitle: source.jobTitle.isEmpty ? _demoDraft.jobTitle : source.jobTitle,
      duration: source.duration.isEmpty ? _demoDraft.duration : source.duration,
      summary: source.summary.isEmpty ? _demoDraft.summary : source.summary,
      isPublic: source.isPublic,
    );
  }

  /// 从职位文案中提取更适合展示为标签的角色名。
  String _extractRoleName(String jobTitle) {
    if (jobTitle.contains('·')) {
      return jobTitle.split('·').last.trim();
    }
    if (jobTitle.contains('-')) {
      return jobTitle.split('-').last.trim();
    }
    return jobTitle.trim();
  }

  /// 构建期望职位标签，优先使用当前草稿值，再补齐设计稿示例。
  List<String> _buildJobTags(String jobTitle) {
    final List<String> result = <String>[];
    final String primaryRole = _extractRoleName(jobTitle);
    if (primaryRole.isNotEmpty) {
      result.add(primaryRole);
    }
    for (final String item in _fallbackJobTags) {
      if (!result.contains(item)) {
        result.add(item);
      }
      if (result.length == 3) {
        break;
      }
    }
    return result;
  }

  /// 构建期望国家标签，保证首个标签与当前草稿一致。
  List<String> _buildCountryTags(String region) {
    final List<String> result = <String>[];
    if (region.trim().isNotEmpty) {
      result.add(region.trim());
    }
    for (final String item in _fallbackCountryTags) {
      if (!result.contains(item)) {
        result.add(item);
      }
      if (result.length == 3) {
        break;
      }
    }
    return result;
  }

  /// 由草稿职位生成第一段工作经历，再拼接设计稿里的补充经历。
  List<_ResumeExperience> _buildExperiences() {
    final List<String> parts = _draft.jobTitle.split('·');
    final String company = parts.isNotEmpty
        ? parts.first.trim()
        : _draft.jobTitle;
    final String role = parts.length > 1
        ? parts.last.trim()
        : _extractRoleName(_draft.jobTitle);

    return <_ResumeExperience>[
      _ResumeExperience(
        company: company.isEmpty ? '伦敦康诺特酒店' : company,
        period: _draft.duration,
        role: role.isEmpty ? '餐饮部·厨师长' : role,
        summary: _draft.summary,
      ),
      ..._fallbackExperiences,
    ];
  }

  /// 只保留薪资左侧输入值，以匹配设计稿当前状态。
  String _extractSalaryValue(String salary) {
    if (salary.contains('-')) {
      return salary.split('-').first.trim();
    }
    if (salary.contains('~')) {
      return salary.split('~').first.trim();
    }
    return salary.trim();
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
                  _draft.name,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: <Widget>[
                    _buildMetaText(_draft.region),
                    _buildMetaText('${_draft.gender}·${_draft.age}岁'),
                    _buildMetaText(_draft.phone),
                  ],
                ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  _ResumeEditorAssets.profileAvatar,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建求职意向区域。
  Widget _buildJobIntentionSection() {
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
            children: _jobTags
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
            children: _countryTags
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
                const Text(
                  '欧元',
                  style: TextStyle(
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
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _salaryValue,
                    style: const TextStyle(
                      color: Color(0xFF171A1D),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 18 / 16,
                    ),
                  ),
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
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FA),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '最高期望',
                    style: TextStyle(
                      color: Color(0xFFBFBFBF),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 18 / 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          for (int index = 0; index < _experiences.length; index++) ...<Widget>[
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
            children: _languageTags
                .map(
                  (String item) => _buildTagChip(
                    label: item,
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

    return Image.asset(
      certificate.previewAssetPath!,
      width: 88,
      height: 88,
      fit: BoxFit.cover,
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
          for (int index = 0; index < _educations.length; index++) ...<Widget>[
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
          item.role,
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
      await ref.read(resumeServiceProvider).saveResume(
        request: _buildSaveRequest(),
      );
      if (!mounted) {
        return;
      }
      _didSave = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isCreateMode ? '创建简历已保存' : '简历修改已保存'),
        ),
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
      await ref.read(resumeServiceProvider).saveResume(
        request: _buildSaveRequest(),
      );
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
              expId: 0,
              company: entry.value.company,
              department: '',
              position: entry.value.role,
              startDate: _parsePeriodStart(entry.value.period),
              endDate: _parsePeriodEnd(entry.value.period),
              isCurrent: entry.value.period.contains('至今'),
              description: entry.value.summary,
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      languages: _languageTags
          .asMap()
          .entries
          .map(
            (entry) => LanguageAbilityBO(
              langId: 0,
              language: _resolveLanguageName(entry.value),
              certificate: entry.value,
              level: '',
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      skillCertificates: _certificates
          .asMap()
          .entries
          .map(
            (entry) => SkillCertificateBO(
              certId: 0,
              name: entry.value.title,
              level: '',
              issuer: entry.value.authority,
              issuedDate: entry.value.issuedAt,
              imageUrl: entry.value.previewFilePaths.isNotEmpty
                  ? entry.value.previewFilePaths.first
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
              eduId: 0,
              school: entry.value.school,
              major: entry.value.subtitle,
              degree: '',
              startYear: _parseEducationStart(entry.value.period),
              endYear: _parseEducationEnd(entry.value.period),
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

  /// 跳转到简历预览页，复用当前页面已经整理好的草稿数据。
  void _openPreview() {
    context.push(RoutePaths.myResumePreview, extra: _currentDraft);
  }

  ResumeDraft get _currentDraft {
    return ResumeDraft(
      name: _draft.name,
      region: _draft.region,
      age: _draft.age,
      gender: _draft.gender,
      phone: _draft.phone,
      salary: _draft.salary.contains('-') || _draft.salary.contains('~')
          ? _draft.salary
          : _salaryValue,
      salaryCurrency: _draft.salaryCurrency,
      jobTitle: _draft.jobTitle,
      duration: _draft.duration,
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
    final String salary = _draft.salary;
    if (salary.contains('-')) {
      return _parseNumeric(salary.split('-').last);
    }
    if (salary.contains('~')) {
      return _parseNumeric(salary.split('~').last);
    }
    return 0;
  }

  double _parseNumeric(String text) {
    final String normalized = text.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  /// 将“2020.09 - 2024.11 / 2020 - 2024 / 2020.09 - 至今”解析为接口需要的开始时间。
  String _parsePeriodStart(String period) {
    final List<String> parts = period.split(RegExp(r'\s*-\s*'));
    return parts.isEmpty ? '' : parts.first.trim();
  }

  /// 将“至今”类文案转换为空结束时间，并配合 `isCurrent` 使用。
  String _parsePeriodEnd(String period) {
    final List<String> parts = period.split(RegExp(r'\s*-\s*'));
    if (parts.length < 2) {
      return '';
    }
    final String end = parts.last.trim();
    return end == '至今' ? '' : end;
  }

  int _parseEducationStart(String period) {
    final String start = _parsePeriodStart(period);
    return int.tryParse(start.split('.').first) ?? 0;
  }

  int _parseEducationEnd(String period) {
    final String end = _parsePeriodEnd(period);
    return int.tryParse(end.split('.').first) ?? 0;
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
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: '语言能力',
      options: _languageSheetOptions,
      initialSelectedValues: _languageTags,
    );

    if (result == null) {
      return;
    }

    setState(() {
      _languageTags
        ..clear()
        ..addAll(result);
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
          title: result.title,
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
          school: result.school,
          subtitle: result.displaySubtitle,
          period: result.displayPeriod,
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
          company: result.company,
          period: result.period.displayText,
          role: result.displayRole,
          summary: result.description.isEmpty ? '未填写工作内容' : result.description,
        ),
      );
    });
  }
}

/// 编辑页资源路径。
class _ResumeEditorAssets {
  static const String completionBadgeBg =
      'assets/images/completion_badge_bg.png';
  static const String basicInfoEdit =
      'assets/images/basic_info_edit.svg';
  static const String profileAvatar =
      'assets/images/profile_avatar.png';
  static const String addCircle = 'assets/images/add_circle.svg';
  static const String tagRemove = 'assets/images/tag_remove.svg';
  static const String tagAdd = 'assets/images/tag_add.svg';
  static const String dropdownArrow =
      'assets/images/dropdown_arrow.png';
  static const String languageTagRemove =
      'assets/images/language_tag_remove.svg';
  static const String certificatePreview =
      'assets/images/certificate_preview.png';
  static const String educationLogo =
      'assets/images/education_logo.png';
}

/// 工作经历展示模型。
class _ResumeExperience {
  const _ResumeExperience({
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

/// 技能证书展示模型。
class _ResumeCertificate {
  const _ResumeCertificate({
    required this.title,
    required this.authority,
    required this.issuedAt,
    this.previewAssetPath,
    this.previewFilePaths = const <String>[],
  });

  final String title;
  final String authority;
  final String issuedAt;
  final String? previewAssetPath;
  final List<String> previewFilePaths;
}

/// 教育经历展示模型。
class _ResumeEducation {
  const _ResumeEducation({
    required this.school,
    required this.subtitle,
    required this.period,
  });

  final String school;
  final String subtitle;
  final String period;
}
