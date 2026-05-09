import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../data/resume_models.dart';
import '../data/resume_providers.dart';
import 'my_resume_editor_page.dart';

/// 我的简历页。
///
/// 当前改为真实接口驱动：
/// 1. 首屏调用 `getMyResume` 拉取当前用户简历；
/// 2. 根据接口状态展示加载、错误、空态或内容态；
/// 3. 仍保留原有编辑入口与管理态 UI；
/// 4. 删除接口暂未接入，管理态下仅给出明确提示。
class MyResumePage extends ConsumerStatefulWidget {
  const MyResumePage({super.key});

  @override
  ConsumerState<MyResumePage> createState() => _MyResumePageState();
}

class _MyResumePageState extends ConsumerState<MyResumePage> {
  ResumeVO? _resume;
  bool _isLoading = true;
  bool _isSavingVisibility = false;
  bool _isManaging = false;
  bool _isResumeVisible = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadResume();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomAction(context),
    );
  }

  /// 拉取当前登录用户的简历，并切换页面状态。
  Future<void> _loadResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ResumeVO resume = await ref
          .read(resumeServiceProvider)
          .getMyResume();
      if (!mounted) {
        return;
      }
      setState(() {
        _resume = resume;
        _isLoading = false;
        _errorMessage = null;
        _isResumeVisible = resume.isPublic ?? _isResumeVisible;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resume = null;
        _isLoading = false;
        _errorMessage = _resolveErrorMessage(error);
      });
    }
  }

  /// 提取简历请求失败时的用户可读文案。
  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '简历加载失败，请稍后重试';
  }

  /// 构建顶部导航栏，处理返回与右上角“管理”文案。
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
            context.pop();
            return;
          }
          context.go(RoutePaths.me);
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
        if (_resume != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _toggleManageMode,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF262626),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                _isManaging ? '完成' : '管理',
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 构建页面主体内容，根据接口状态切换不同 UI。
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _ResumeErrorState(message: _errorMessage!, onRetry: _loadResume);
    }
    final ResumeVO? resume = _resume;
    if (resume == null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
        children: <Widget>[
          const Text(
            '选择默认展示简历',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildEmptyState(),
        ],
      );
    }

    final _ResumeItemData item = resume.toResumeItemData();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      children: <Widget>[
        Text(
          _isManaging ? '管理我的简历' : '选择默认展示简历',
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
        const SizedBox(height: 12),
        _buildResumeCard(item),
      ],
    );
  }

  /// 构建单张简历卡片，展示接口返回的真实简历数据。
  Widget _buildResumeCard(_ResumeItemData item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: _isManaging ? null : () => _openResumeEditor(),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 20,
                  backgroundColor: item.avatarColor,
                  child: Icon(item.avatarIcon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildProfileMeta(item)),
                if (!_isManaging)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFBFBFBF),
                    size: 18,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Icon(
                Icons.work_outline_rounded,
                size: 14,
                color: Color(0xFFBFBFBF),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.jobTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 16 / 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.duration,
                style: const TextStyle(
                  color: Color(0xFF8C8C8C),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.summary,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          if (_isManaging)
            _buildManageActions()
          else
            Row(
              children: <Widget>[
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(10),
                  child: const Row(
                    children: <Widget>[
                      Icon(
                        Icons.radio_button_checked_rounded,
                        size: 20,
                        color: Color(0xFF096DD9),
                      ),
                      SizedBox(width: 7),
                      Text(
                        '已设默认',
                        style: TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Text(
                  '可见',
                  style: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: _isResumeVisible,
                    onChanged: _isSavingVisibility
                        ? null
                        : _updateResumeVisibility,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF096DD9),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFD9D9D9),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建管理态下的底部操作区。
  Widget _buildManageActions() {
    return Row(
      children: <Widget>[
        const Row(
          children: <Widget>[
            Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: Color(0xFF096DD9),
            ),
            SizedBox(width: 7),
            Text(
              '已设默认',
              style: TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: _showDeleteUnavailableMessage,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFFD9363E),
                ),
                SizedBox(width: 4),
                Text(
                  '删除简历',
                  style: TextStyle(
                    color: Color(0xFFD9363E),
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

  /// 构建头像右侧的基本信息区域。
  Widget _buildProfileMeta(_ResumeItemData item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item.name,
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 20 / 15,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _buildMetaText(item.region),
            _buildSeparator(),
            _buildMetaText(item.age),
            _buildSeparator(),
            _buildMetaText(item.gender),
            _buildSeparator(),
            _buildMetaText(item.salary),
          ],
        ),
      ],
    );
  }

  /// 构建基础信息里的灰色文本。
  Widget _buildMetaText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF595959),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      ),
    );
  }

  /// 构建基础信息之间的分隔符。
  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '|',
        style: TextStyle(
          color: Color(0xFFBFBFBF),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 16 / 12,
        ),
      ),
    );
  }

  /// 构建底部固定操作区。
  Widget _buildBottomAction(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _openCreateResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF096DD9),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '创建简历',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 22 / 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 构建空状态，用于后端未返回简历时的页面反馈。
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        children: <Widget>[
          Icon(Icons.description_outlined, size: 32, color: Color(0xFFBFBFBF)),
          SizedBox(height: 12),
          Text(
            '暂无简历',
            style: TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 切换页面右上角的管理状态。
  void _toggleManageMode() {
    setState(() => _isManaging = !_isManaging);
  }

  /// 进入创建简历页，使用空白初始值。
  Future<void> _openCreateResume() async {
    final bool? didSave = await context.push<bool>(
      RoutePaths.myResumeEditor,
      extra: ResumeEditorArgs.create(isPublic: _isResumeVisible),
    );
    if (didSave == true && mounted) {
      await _loadResume();
    }
  }

  /// 进入编辑简历页，并把真实接口对象直接传给编辑页。
  Future<void> _openResumeEditor() async {
    final ResumeVO? resume = _resume;
    if (resume == null) {
      return;
    }
    final bool? didSave = await context.push<bool>(
      RoutePaths.myResumeEditor,
      extra: ResumeEditorArgs.edit(resume),
    );
    if (didSave == true && mounted) {
      await _loadResume();
    }
  }

  /// 切换简历公开状态，并通过保存接口同步到服务端。
  Future<void> _updateResumeVisibility(bool value) async {
    final ResumeVO? resume = _resume;
    if (_isSavingVisibility || resume == null) {
      return;
    }

    setState(() {
      _isSavingVisibility = true;
      _isResumeVisible = value;
    });

    try {
      await ref
          .read(resumeServiceProvider)
          .saveResume(request: resume.toSaveResumeBO(isPublic: value));
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingVisibility = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value ? '已设为可见' : '已设为不可见')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingVisibility = false;
        _isResumeVisible = resume.isPublic ?? !value;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    }
  }

  /// 提示当前文档未提供删除简历接口，避免误导用户。
  void _showDeleteUnavailableMessage() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('当前 API 文档未提供删除简历接口')));
  }
}

class _ResumeErrorState extends StatelessWidget {
  const _ResumeErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  /// 简历加载失败时展示错误提示与重试入口。
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFBFBFBF),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 简历卡片的本地展示数据。
class _ResumeItemData {
  const _ResumeItemData({
    required this.name,
    required this.region,
    required this.age,
    required this.gender,
    required this.phone,
    required this.salary,
    required this.jobTitle,
    required this.duration,
    required this.summary,
    required this.avatarColor,
    required this.avatarIcon,
  });

  final String name;
  final String region;
  final String age;
  final String gender;
  final String phone;
  final String salary;
  final String jobTitle;
  final String duration;
  final String summary;
  final Color avatarColor;
  final IconData avatarIcon;
}

extension on ResumeVO {
  /// 将接口返回的简历映射为当前列表卡片展示数据。
  _ResumeItemData toResumeItemData() {
    final WorkExperienceVO? firstExperience = workExperiences.isEmpty
        ? null
        : workExperiences.first;
    final String title = firstExperience?.position.trim().isNotEmpty == true
        ? firstExperience!.position.trim()
        : (jobIntention.positions.isEmpty
              ? '期望职位待完善'
              : jobIntention.positions.first);
    final String duration = firstExperience == null
        ? (updatedAt.isEmpty ? '刚刚更新' : updatedAt)
        : firstExperience.isCurrent
        ? '${firstExperience.startDate}-至今'
        : '${firstExperience.startDate}-${firstExperience.endDate}';
    final String summaryText = selfEvaluation.trim().isNotEmpty
        ? selfEvaluation.trim()
        : (firstExperience?.description.trim().isNotEmpty == true
              ? firstExperience!.description.trim()
              : '请完善自我评价');

    return _ResumeItemData(
      name: basicInfo.realName.isEmpty ? '未填写姓名' : basicInfo.realName,
      region: basicInfo.currentLocation.isEmpty
          ? '地区待完善'
          : basicInfo.currentLocation,
      age: basicInfo.age > 0 ? '${basicInfo.age}岁' : '年龄待完善',
      gender: basicInfo.gender.isEmpty ? '性别待完善' : basicInfo.gender,
      phone: basicInfo.phone,
      salary: _formatSalary(),
      jobTitle: title,
      duration: duration,
      summary: summaryText,
      avatarColor: const Color(0xFF8FB6FF),
      avatarIcon: Icons.person,
    );
  }

  /// 将当前简历详情转换成保存接口需要的全量请求。
  SaveResumeBO toSaveResumeBO({required bool isPublic}) {
    return SaveResumeBO(
      jobIntention: JobIntentionBO(
        positions: jobIntention.positions,
        countries: jobIntention.countries,
        salaryMin: jobIntention.salaryMin,
        salaryMax: jobIntention.salaryMax,
        salaryCurrency: jobIntention.salaryCurrency,
      ),
      workExperiences: workExperiences
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
              description: entry.value.description,
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      languages: languages
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
      skillCertificates: skillCertificates
          .asMap()
          .entries
          .map(
            (entry) => SkillCertificateBO(
              certId: entry.value.certId,
              name: entry.value.name,
              level: entry.value.level,
              issuer: entry.value.issuer,
              issuedDate: entry.value.issuedDate,
              imageUrl: entry.value.imageUrl,
              sortOrder: entry.key + 1,
            ),
          )
          .toList(growable: false),
      educations: educations
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
      selfEvaluation: selfEvaluation,
      isPublic: isPublic,
    );
  }

  /// 组装简历页展示或编辑页传值使用的薪资文案。
  String _formatSalary({bool raw = false}) {
    final String currency = jobIntention.salaryCurrency.isEmpty
        ? ''
        : '${jobIntention.salaryCurrency} ';
    final String minText = _formatDouble(jobIntention.salaryMin);
    final String maxText = _formatDouble(jobIntention.salaryMax);
    if (jobIntention.salaryMin <= 0 && jobIntention.salaryMax <= 0) {
      return raw ? '' : '薪资待完善';
    }
    if (jobIntention.salaryMax > 0) {
      return '$currency$minText-$maxText';
    }
    return '$currency$minText';
  }

  String _formatDouble(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}
