import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../data/resume_models.dart';
import '../data/resume_providers.dart';
import 'my_resume_editor_page.dart';

/// 简历预览页，仅展示编辑页传入的真实数据快照。
class MyResumePreviewPage extends ConsumerStatefulWidget {
  const MyResumePreviewPage({
    super.key,
    this.args,
    this.userId,
    this.title = '',
  });

  final ResumePreviewArgs? args;
  final int? userId;
  final String title;

  @override
  ConsumerState<MyResumePreviewPage> createState() =>
      _MyResumePreviewPageState();
}

class _MyResumePreviewPageState extends ConsumerState<MyResumePreviewPage> {
  ResumePreviewArgs? _remoteArgs;
  bool _isLoading = false;
  String? _errorMessage;

  /// 空入参时提供一个纯空白快照，避免页面崩溃。
  ResumePreviewArgs get _resolvedArgs {
    return widget.args ??
        _remoteArgs ??
        const ResumePreviewArgs(
          draft: ResumeDraft(),
          avatarUrl: '',
          positions: <String>[],
          countries: <String>[],
          languages: <String>[],
          experiences: <ResumePreviewExperience>[],
          certificates: <ResumePreviewCertificate>[],
          educations: <ResumePreviewEducation>[],
        );
  }

  /// 预览页始终以当前草稿为主，避免再从别处拼接示例值。
  ResumeDraft get _draft => _resolvedArgs.draft;

  /// 头像下方优先展示首条真实工作经历的公司名。
  String get _companyName {
    if (_resolvedArgs.experiences.isNotEmpty) {
      return _resolvedArgs.experiences.first.company;
    }
    final List<String> parts = _draft.jobTitle.split('·');
    return parts.isEmpty ? '' : parts.first.trim();
  }

  /// 头像下方优先展示首条真实工作经历的职位名。
  String get _roleName {
    if (_resolvedArgs.experiences.isNotEmpty) {
      return _resolvedArgs.experiences.first.role;
    }
    final List<String> parts = _draft.jobTitle.split('·');
    if (parts.length > 1) {
      return parts.sublist(1).join('·').trim();
    }
    return _draft.jobTitle.trim();
  }

  /// 求职意向优先展示真实期望职位列表的第一个值。
  String get _primaryJobTitle {
    if (_resolvedArgs.positions.isNotEmpty) {
      return _resolvedArgs.positions.first;
    }
    if (_roleName.isNotEmpty) {
      return _roleName;
    }
    return '我的.暂无期望职位'.tr();
  }

  /// 求职意向的国家地区展示只使用真实标签。
  String get _countryText {
    if (_resolvedArgs.countries.isEmpty) {
      return '我的.暂无期望国家地区'.tr();
    }
    return _resolvedArgs.countries.join(' · ');
  }

  /// 薪资展示保留真实币种与区间，不再补任何默认值。
  String get _salaryText {
    if (_draft.salary.trim().isEmpty) {
      return '我的.薪资待完善'.tr();
    }
    if (_draft.salaryCurrency.trim().isEmpty) {
      return _draft.salary.trim();
    }
    return '${_draft.salaryCurrency} ${_draft.salary.trim()}';
  }

  bool get _shouldLoadByUserId => widget.args == null && widget.userId != null;

  @override
  void initState() {
    super.initState();
    if (_shouldLoadByUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _loadResumeDetail();
      });
    }
  }

  Future<void> _loadResumeDetail() async {
    final int? userId = widget.userId;
    if (userId == null || _isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ResumeVO resume = await ref
          .read(resumeServiceProvider)
          .getResumeByUserId(userId: userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _remoteArgs = _mapResumeToPreviewArgs(resume);
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _normalizeError(error);
      });
    }
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '我的.简历加载失败'.tr() : message;
  }

  ResumePreviewArgs _mapResumeToPreviewArgs(ResumeVO resume) {
    return ResumePreviewArgs(
      draft: ResumeDraft(
        name: resume.basicInfo.realName,
        region: resume.basicInfo.currentLocation,
        age: resume.basicInfo.age > 0 ? resume.basicInfo.age.toString() : '',
        gender: resume.basicInfo.gender,
        phone: resume.basicInfo.phone,
        salary: _formatSalaryRange(
          resume.jobIntention.salaryMin,
          resume.jobIntention.salaryMax,
        ),
        salaryCurrency: resume.jobIntention.salaryCurrency,
        jobTitle: _joinNonEmpty(resume.jobIntention.positions),
        summary: resume.selfEvaluation,
        isPublic: resume.isPublic ?? true,
      ),
      avatarUrl: resume.basicInfo.avatarUrl,
      positions: _cleanList(resume.jobIntention.positions),
      countries: _cleanList(resume.jobIntention.countries),
      languages: resume.languages
          .map(_formatLanguageLabel)
          .where((String item) => item.isNotEmpty)
          .toList(growable: false),
      experiences: resume.workExperiences
          .map(
            (WorkExperienceVO item) => ResumePreviewExperience(
              company: item.company.trim(),
              period: _formatExperiencePeriod(
                item.startDate,
                item.endDate,
                item.isCurrent,
              ),
              role: _formatExperienceRole(item.department, item.position),
              summary: item.description.trim(),
            ),
          )
          .toList(growable: false),
      certificates: resume.skillCertificates
          .map(
            (SkillCertificateVO item) => ResumePreviewCertificate(
              title: _formatCertificateTitle(item.name, item.level),
              period: item.issuedDate.trim(),
              issuer: item.issuer.trim(),
              networkImageUrls: item.imageUrl.trim().isEmpty
                  ? const <String>[]
                  : <String>[item.imageUrl.trim()],
            ),
          )
          .toList(growable: false),
      educations: resume.educations
          .map(
            (EducationVO item) => ResumePreviewEducation(
              school: item.school.trim(),
              period: _formatEducationPeriod(item.startYear, item.endYear),
              major: _formatEducationMajor(item.major, item.degree),
            ),
          )
          .toList(growable: false),
    );
  }

  List<String> _cleanList(List<String> values) {
    return values
        .map((String item) => item.trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  String _joinNonEmpty(List<String> values) {
    return _cleanList(values).join('·');
  }

  String _formatSalaryRange(double min, double max) {
    final String minText = _formatAmount(min);
    final String maxText = _formatAmount(max);
    if (minText.isEmpty && maxText.isEmpty) {
      return '';
    }
    if (minText.isEmpty) {
      return maxText;
    }
    if (maxText.isEmpty || minText == maxText) {
      return minText;
    }
    return '$minText-$maxText';
  }

  String _formatAmount(double value) {
    if (value <= 0) {
      return '';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toString();
  }

  String _formatLanguageLabel(LanguageAbilityVO item) {
    final List<String> parts = <String>[
      item.language.trim(),
      item.certificate.trim(),
      item.level.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join(' · ');
  }

  String _formatExperienceRole(String department, String position) {
    final List<String> parts = <String>[
      department.trim(),
      position.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join(' · ');
  }

  String _formatExperiencePeriod(
    String startDate,
    String endDate,
    bool isCurrent,
  ) {
    final String start = startDate.trim();
    final String end = isCurrent ? '我的.至今'.tr() : endDate.trim();
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    return '$start - $end';
  }

  String _formatCertificateTitle(String name, String level) {
    final List<String> parts = <String>[
      name.trim(),
      level.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join(' · ');
  }

  String _formatEducationPeriod(int startYear, int endYear) {
    final String start = startYear > 0 ? startYear.toString() : '';
    final String end = endYear > 0 ? endYear.toString() : '';
    if (start.isEmpty && end.isEmpty) {
      return '';
    }
    if (start.isEmpty) {
      return end;
    }
    if (end.isEmpty) {
      return start;
    }
    return '$start - $end';
  }

  String _formatEducationMajor(String major, String degree) {
    final List<String> parts = <String>[
      major.trim(),
      degree.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join(' · ');
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(
      widget.userId != null ? RoutePaths.home : RoutePaths.myResumeEditor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets viewPadding = MediaQuery.paddingOf(context);
    final String pageTitle = widget.title.isEmpty ? '我的.预览'.tr() : widget.title;

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
          onPressed: () => _handleBack(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF262626),
          ),
        ),
        title: Text(
          pageTitle,
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _shouldLoadByUserId && _isLoading && _remoteArgs == null
          ? const Center(child: CircularProgressIndicator())
          : _shouldLoadByUserId && _errorMessage != null && _remoteArgs == null
          ? _buildLoadErrorState()
          : ListView(
              padding: EdgeInsets.only(bottom: 16 + viewPadding.bottom),
              children: <Widget>[
                _buildProfileSection(),
                const SizedBox(height: 2),
                _buildIntentionSection(),
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
    );
  }

  Widget _buildLoadErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _errorMessage ?? '我的.简历加载失败'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadResumeDetail,
              child: Text('我的.重新加载'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建顶部资料区，只展示真实姓名、头像和岗位信息。
  Widget _buildProfileSection() {
    final String name = _draft.name.trim().isEmpty ? '我的.未填写姓名'.tr() : _draft.name;

    return Container(
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
                    name,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 28 / 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_companyName.isEmpty && _roleName.isEmpty)
                    _buildEmptyText('我的.暂无岗位信息'.tr())
                  else
                    Row(
                      children: <Widget>[
                        if (_companyName.isNotEmpty)
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
                        if (_companyName.isNotEmpty && _roleName.isNotEmpty)
                          const SizedBox(width: 8),
                        if (_roleName.isNotEmpty)
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
          _buildAvatar(),
        ],
      ),
    );
  }

  /// 构建求职意向区，仅展示真实国家、职位和薪资。
  Widget _buildIntentionSection() {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('我的.求职意向'.tr()),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Color(0xFFBFBFBF),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _countryText,
                    style: const TextStyle(
                      color: Color(0xFF595959),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    _primaryJobTitle,
                    maxLines: 2,
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

  /// 构建工作经历区，完整展示当前真实经历列表。
  Widget _buildWorkExperienceSection() {
    final List<ResumePreviewExperience> experiences = _resolvedArgs.experiences;
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('我的.工作经历'.tr()),
            const SizedBox(height: 20),
            if (experiences.isEmpty)
              _buildEmptyText('我的.暂无工作经历'.tr())
            else
              for (
                int index = 0;
                index < experiences.length;
                index++
              ) ...<Widget>[
                _buildExperienceItem(experiences[index]),
                if (index != experiences.length - 1) const SizedBox(height: 24),
              ],
          ],
        ),
      ),
    );
  }

  /// 构建语言能力区，仅展示真实语言标签。
  Widget _buildLanguageSection() {
    final List<String> languages = _resolvedArgs.languages;
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('我的.语言能力'.tr()),
            const SizedBox(height: 20),
            if (languages.isEmpty)
              _buildEmptyText('我的.暂无语言能力'.tr())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: languages.map(_buildTag).toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建技能证书区，按真实证书列表渲染。
  Widget _buildCertificateSection() {
    final List<ResumePreviewCertificate> certificates =
        _resolvedArgs.certificates;
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('我的.技能证书'.tr()),
            const SizedBox(height: 20),
            if (certificates.isEmpty)
              _buildEmptyText('我的.暂无技能证书'.tr())
            else
              for (
                int index = 0;
                index < certificates.length;
                index++
              ) ...<Widget>[
                _buildCertificateItem(certificates[index]),
                if (index != certificates.length - 1)
                  const SizedBox(height: 20),
              ],
          ],
        ),
      ),
    );
  }

  /// 构建教育经历区，按真实教育列表渲染。
  Widget _buildEducationSection() {
    final List<ResumePreviewEducation> educations = _resolvedArgs.educations;
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 15, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('我的.教育经历'.tr()),
            const SizedBox(height: 20),
            if (educations.isEmpty)
              _buildEmptyText('我的.暂无教育经历'.tr())
            else
              for (
                int index = 0;
                index < educations.length;
                index++
              ) ...<Widget>[
                _buildEducationItem(educations[index]),
                if (index != educations.length - 1) const SizedBox(height: 20),
              ],
          ],
        ),
      ),
    );
  }

  /// 构建自我评价区，只展示真实输入内容。
  Widget _buildSelfEvaluationSection() {
    return _buildSectionContainer(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle('我的.自我评价'.tr()),
            const SizedBox(height: 20),
            if (_draft.summary.trim().isEmpty)
              _buildEmptyText('我的.暂无自我评价'.tr())
            else
              Text(
                _draft.summary,
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

  /// 渲染单条工作经历。
  Widget _buildExperienceItem(ResumePreviewExperience experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                experience.company.isEmpty
                    ? '我的.未填写公司名称'.tr()
                    : experience.company,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
            if (experience.period.isNotEmpty) ...<Widget>[
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
          ],
        ),
        const SizedBox(height: 10),
        Text(
          experience.role.isEmpty ? '我的.未填写职位'.tr() : experience.role,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          experience.summary.isEmpty
              ? '我的.未填写工作内容'.tr()
              : experience.summary,
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

  /// 渲染单条证书信息与其真实图片。
  Widget _buildCertificateItem(ResumePreviewCertificate certificate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                certificate.title,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
            if (certificate.period.isNotEmpty) ...<Widget>[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  certificate.period,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 18 / 13,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          certificate.issuer.isEmpty
              ? '我的.未填写发证机构'.tr()
              : certificate.issuer,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
        const SizedBox(height: 12),
        _buildCertificateImages(certificate),
      ],
    );
  }

  /// 渲染单条教育经历。
  Widget _buildEducationItem(ResumePreviewEducation education) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.school_outlined,
            color: Color(0xFF8C8C8C),
            size: 26,
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
                        education.school.isEmpty
                            ? '我的.未填写学校'.tr()
                            : education.school,
                        style: const TextStyle(
                          color: Color(0xFF262626),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 22 / 16,
                        ),
                      ),
                    ),
                    if (education.period.isNotEmpty) ...<Widget>[
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          education.period,
                          style: const TextStyle(
                            color: Color(0xFF8C8C8C),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            height: 18 / 13,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  education.major.isEmpty
                      ? '我的.未填写专业学历'.tr()
                      : education.major,
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
    );
  }

  /// 根据图片来源类型渲染本地或网络证书图。
  Widget _buildCertificateImages(ResumePreviewCertificate certificate) {
    if (certificate.localImagePaths.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: certificate.localImagePaths
            .map(
              (String path) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(path),
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                ),
              ),
            )
            .toList(growable: false),
      );
    }
    if (certificate.networkImageUrls.isNotEmpty) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: certificate.networkImageUrls
            .map(
              (String url) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: url,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _buildImagePlaceholder(),
                ),
              ),
            )
            .toList(growable: false),
      );
    }
    return _buildImagePlaceholder();
  }

  /// 渲染统一图片占位，避免继续展示任何示例素材。
  Widget _buildImagePlaceholder() {
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

  /// 渲染标签样式的只读内容。
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

  /// 构建通用分组容器。
  Widget _buildSectionContainer({required Widget child}) {
    return ColoredBox(color: Colors.white, child: child);
  }

  /// 构建通用分组标题。
  Widget _buildSectionTitle(String title) {
    return Row(
      children: <Widget>[
        Container(width: 3, height: 12, color: const Color(0xFF096DD9)),
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

  /// 构建统一空态文本。
  Widget _buildEmptyText(String text) {
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

  /// 构建头像，优先展示真实网络头像。
  Widget _buildAvatar() {
    final String avatarUrl = _resolvedArgs.avatarUrl;
    if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
      return AppUserAvatar(
        imageUrl: avatarUrl,
        size: 60,
        placeholder: _buildAvatarPlaceholder(),
      );
    }
    return _buildAvatarPlaceholder();
  }

  /// 未上传头像时展示中性的占位样式。
  Widget _buildAvatarPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFFE9EEF5),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Color(0xFF8C8C8C), size: 28),
    );
  }
}
