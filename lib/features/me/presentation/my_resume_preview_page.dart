import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import 'my_resume_editor_page.dart';

/// 简历预览页，按 Figma「我的简历-预览」节点实现。
class MyResumePreviewPage extends StatelessWidget {
  const MyResumePreviewPage({super.key, this.draft});

  final ResumeDraft? draft;

  static const ResumeDraft _demoDraft = ResumeDraft(
    name: '程先生',
    region: '德国·法国',
    salary: '2,500~3,500',
    jobTitle: '伦敦康诺特酒店·厨师长',
    duration: '2024.11 - 至今',
    summary:
        '本人从事餐饮烹饪工作多年，具备扎实的烹调功底，熟练掌握煎、炒、烹、炸、蒸等各类烹饪技法，擅长各类中餐菜品制作，能精准把控火候与口味，注重菜品营养搭配和出品品相，保证出品稳定优质。工作中，我严格恪守食品安全与后厨卫生规范，细心把控食材处理、烹饪全流程，严守卫生标准，杜绝安全隐患。我吃苦耐劳，执行力强，服从管理安排，善于配合团队完成后厨各项工作，具备良好的职业素养和团队协作意识。始终秉持精益求精的做菜理念，用心做好每一道菜品，全力保障用餐品质。',
  );

  static const List<_PreviewExperience> _fallbackExperiences =
      <_PreviewExperience>[
        _PreviewExperience(
          company: '香港文华东方酒店',
          period: '2020.09 - 2024.11',
          role: '餐饮部·高级厨师',
          summary:
              '负责菜品的具体制作与出品把控，熟练运用各类烹饪技法，严格按照菜单要求和标准处理食材、把控火候，确保菜品口味、品相稳定统一。严格遵守食品安全与后厨操作规范，做好食材清洗、加工及烹饪全流程卫生管控，减少食材损耗。服从厨师长的分工安排，配合团队完成后厨日常运营工作，主动学习新的烹饪技巧和菜品做法，及时调整制作细节，全力保障每一道菜品符合门店标准和顾客需求。',
        ),
      ];

  static const List<String> _languageTags = <String>[
    '德福TestDaF',
    '歌德 C2',
    '法语专业四级',
  ];

  static const _PreviewCertificate _certificate = _PreviewCertificate(
    title: '中式烹调师·五级',
    period: '2016.10',
    issuer: '人力资源社会保障部',
  );

  static const _PreviewEducation _education = _PreviewEducation(
    school: '扬州大学',
    period: '2010 - 2013',
    major: '烹饪与营养教育',
  );

  ResumeDraft get _resolvedDraft {
    final ResumeDraft source = draft ?? const ResumeDraft();
    return ResumeDraft(
      name: source.name.isEmpty ? _demoDraft.name : source.name,
      region: source.region.isEmpty ? _demoDraft.region : source.region,
      age: source.age,
      gender: source.gender,
      phone: source.phone,
      salary: source.salary.isEmpty ? _demoDraft.salary : source.salary,
      jobTitle: source.jobTitle.isEmpty ? _demoDraft.jobTitle : source.jobTitle,
      duration: source.duration.isEmpty ? _demoDraft.duration : source.duration,
      summary: source.summary.isEmpty ? _demoDraft.summary : source.summary,
    );
  }

  String get _companyName {
    final List<String> parts = _resolvedDraft.jobTitle.split('·');
    return parts.isEmpty ? '伦敦康诺特酒店' : parts.first.trim();
  }

  String get _roleName {
    final List<String> parts = _resolvedDraft.jobTitle.split('·');
    if (parts.length > 1) {
      return parts.sublist(1).join('·').trim();
    }
    return _resolvedDraft.jobTitle.trim().isEmpty ? '厨师长' : _resolvedDraft.jobTitle.trim();
  }

  String get _primaryJobTitle {
    final String role = _roleName;
    return role.isEmpty ? '中餐厨师' : role;
  }

  String get _salaryText {
    final String value = _resolvedDraft.salary.trim().replaceAll('-', '~');
    if (value.isEmpty) {
      return '€2,500~3,500';
    }
    return value.startsWith('€') ? value : '€$value';
  }

  _PreviewExperience get _primaryExperience {
    final String role = _roleName;
    final String experienceRole = role.contains('·') ? role : '餐饮部·$role';
    return _PreviewExperience(
      company: _companyName,
      period: _resolvedDraft.duration,
      role: experienceRole,
      summary:
          '全面统筹厨房日常运营管理，制定并优化菜单，负责菜品研发、成本核算与食材损耗控制。统筹后厨人员分工、排班及技能培训，提升团队整体厨艺水平。严格监督食材采购、验收与库存管理，落实食品安全与卫生规范，排查安全隐患。协调前厅与后厨的沟通衔接，处理菜品相关客诉及突发问题，规范厨房操作流程，保障厨房高效、有序运转，兼顾出品质量与运营效率。',
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);
    final ResumeDraft previewDraft = _resolvedDraft;
    final List<_PreviewExperience> experiences = <_PreviewExperience>[
      _primaryExperience,
      ..._fallbackExperiences,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(RoutePaths.myResumeEditor);
          },
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF262626),
          ),
        ),
        title: const Text(
          '预览',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 16 + viewPadding.bottom),
        children: <Widget>[
          _buildProfileSection(previewDraft),
          const SizedBox(height: 2),
          _buildIntentionSection(previewDraft),
          const SizedBox(height: 2),
          _buildWorkExperienceSection(experiences),
          const SizedBox(height: 2),
          _buildLanguageSection(),
          const SizedBox(height: 2),
          _buildCertificateSection(),
          const SizedBox(height: 2),
          _buildEducationSection(),
          const SizedBox(height: 2),
          _buildSelfEvaluationSection(previewDraft),
        ],
      ),
    );
  }

  Widget _buildProfileSection(ResumeDraft previewDraft) {
    return Container(
      height: 100,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    previewDraft.name,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 28 / 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          _companyName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF595959),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _roleName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF595959),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          ClipOval(
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image.asset(
                _ResumePreviewAssets.avatar,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntentionSection(ResumeDraft previewDraft) {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('求职意向'),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Color(0xFFBFBFBF),
                ),
                const SizedBox(width: 4),
                Text(
                  previewDraft.region,
                  style: const TextStyle(
                    color: Color(0xFF595959),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _primaryJobTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _salaryText,
                  style: const TextStyle(
                    color: Color(0xFFFE5815),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 24 / 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkExperienceSection(List<_PreviewExperience> experiences) {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('工作经历'),
            const SizedBox(height: 20),
            _buildExperienceItem(experiences.first),
            const SizedBox(height: 24),
            _buildExperienceItem(experiences.last),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection() {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('语言能力'),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languageTags.map(_buildTag).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificateSection() {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('技能证书'),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    _certificate.title,
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
                  child: Text(
                    _certificate.period,
                    style: const TextStyle(
                      color: Color(0xFF8C8C8C),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      height: 18 / 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _certificate.issuer,
              style: const TextStyle(
                color: Color(0xFF595959),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 88,
                height: 88,
                child: Image.asset(
                  _ResumePreviewAssets.certificate,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationSection() {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('教育经历'),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.asset(
                      _ResumePreviewAssets.education,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                _education.school,
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
                              child: Text(
                                _education.period,
                                style: const TextStyle(
                                  color: Color(0xFF8C8C8C),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  height: 18 / 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _education.major,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfEvaluationSection(ResumeDraft previewDraft) {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('自我评价'),
            const SizedBox(height: 20),
            Text(
              previewDraft.summary,
              style: const TextStyle(
                color: Color(0xFF595959),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 24 / 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperienceItem(_PreviewExperience experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                experience.company,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              experience.period,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 18 / 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          experience.role,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          experience.summary,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 24 / 14,
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF262626),
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 20 / 14,
        ),
      ),
    );
  }

  Widget _buildSectionContainer({required Widget child}) {
    return ColoredBox(color: Colors.white, child: child);
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: <Widget>[
        Container(
          width: 3,
          height: 12,
          color: const Color(0xFF096DD9),
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
      ],
    );
  }
}

class _PreviewExperience {
  const _PreviewExperience({
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

class _PreviewCertificate {
  const _PreviewCertificate({
    required this.title,
    required this.period,
    required this.issuer,
  });

  final String title;
  final String period;
  final String issuer;
}

class _PreviewEducation {
  const _PreviewEducation({
    required this.school,
    required this.period,
    required this.major,
  });

  final String school;
  final String period;
  final String major;
}

class _ResumePreviewAssets {
  static const String avatar =
      'assets/images/resume_preview/resume_preview_avatar-56586a.png';
  static const String certificate =
      'assets/images/resume_preview/resume_preview_certificate-56586a.png';
  static const String education =
      'assets/images/resume_preview/resume_preview_education-56586a.png';
}
