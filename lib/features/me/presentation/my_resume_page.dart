import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../data/resume_models.dart';
import '../data/resume_providers.dart';
import 'my_resume_editor_page.dart';

/// 我的简历页。
///
/// 当前改为真实接口驱动：
/// 1. 首屏调用 `listMyResumes` 拉取当前用户简历摘要列表；
/// 2. 点击卡片时按 `resumeId` 再拉取详情进入编辑；
/// 3. 管理态支持按卡片设为默认、删除和切换公开状态；
/// 3. 根据接口状态展示加载、错误、空态或内容态；
/// 4. 仍保留原有编辑入口与管理态 UI。
class MyResumePage extends ConsumerStatefulWidget {
  const MyResumePage({super.key});

  @override
  ConsumerState<MyResumePage> createState() => _MyResumePageState();
}

class _MyResumePageState extends ConsumerState<MyResumePage> {
  List<ResumeListItemVO> _resumes = const <ResumeListItemVO>[];
  bool _isLoading = true;
  bool _isManaging = false;
  int? _savingVisibilityResumeId;
  int? _settingDefaultResumeId;
  int? _deletingResumeId;
  bool _isCreatingResume = false;
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

  /// 拉取当前登录用户的简历列表，并切换页面状态。
  Future<void> _loadResume() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final List<ResumeListItemVO> resumes = await ref
          .read(resumeServiceProvider)
          .listMyResumes();
      if (!mounted) {
        return;
      }
      setState(() {
        _resumes = resumes;
        _isLoading = false;
        _errorMessage = null;
        _isManaging = resumes.isNotEmpty && _isManaging;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _resumes = const <ResumeListItemVO>[];
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
        if (_resumes.isNotEmpty)
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
    if (_resumes.isEmpty) {
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

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      itemCount: _resumes.length + 1,
      separatorBuilder: (_, index) =>
          index == 0 ? const SizedBox(height: 12) : const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        if (index == 0) {
          return Text(
            _isManaging ? '管理我的简历' : '选择默认展示简历',
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          );
        }
        final ResumeListItemVO item = _resumes[index - 1];
        return _buildResumeCard(item);
      },
    );
  }

  /// 基于列表接口的简历摘要构建卡片展示数据。
  _ResumeItemData _buildResumeItemData(ResumeListItemVO item) {
    final LatestExperienceVO? latestExperience = item.latestExperience;
    final String title = latestExperience?.position.trim().isNotEmpty == true
        ? latestExperience!.position.trim()
        : (item.targetPositions.isEmpty ? '期望职位待完善' : item.targetPositions.first);
    final String duration = latestExperience == null
        ? (item.updatedAt.isEmpty ? '刚刚更新' : item.updatedAt)
        : latestExperience.isCurrent
        ? '${latestExperience.startDate}-至今'
        : '${latestExperience.startDate}-${latestExperience.endDate ?? '至今'}';
    final String summary = latestExperience?.description.trim().isNotEmpty == true
        ? latestExperience!.description.trim()
        : (latestExperience?.company.trim().isNotEmpty == true
              ? latestExperience!.company.trim()
              : '请完善工作经历');

    return _ResumeItemData(
      name: item.nickname.trim().isEmpty ? '未命名用户' : item.nickname.trim(),
      region: item.currentLocation.trim().isEmpty ? '地区待完善' : item.currentLocation.trim(),
      age: item.age != null && item.age! > 0 ? '${item.age}岁' : '年龄待完善',
      gender: item.gender.trim().isEmpty ? '性别待完善' : item.gender.trim(),
      salary: _formatSalaryText(item),
      jobTitle: title,
      duration: duration,
      summary: summary,
      avatarUrl: item.avatarUrl,
      avatarFallbackText: _buildAvatarFallbackText(item.nickname),
    );
  }

  /// 构建单张简历卡片，展示列表接口返回的摘要数据。
  Widget _buildResumeCard(ResumeListItemVO resume) {
    final _ResumeItemData item = _buildResumeItemData(resume);
    final bool isSavingVisibility = _savingVisibilityResumeId == resume.resumeId;
    final bool isSettingDefault = _settingDefaultResumeId == resume.resumeId;
    final bool isDeleting = _deletingResumeId == resume.resumeId;
    final bool canSetDefault = !resume.isDefault && !isSettingDefault;

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
            onTap: _isManaging ? null : () => _openResumeEditor(resume),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: <Widget>[
                AppUserAvatar(
                  imageUrl: item.avatarUrl,
                  size: 40,
                  backgroundColor: const Color(0xFFF0F5FF),
                  placeholder: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8FB6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item.avatarFallbackText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
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
            _buildManageActions(
              resume: resume,
              isSettingDefault: isSettingDefault,
              isDeleting: isDeleting,
              canSetDefault: canSetDefault,
            )
          else
            Row(
              children: <Widget>[
                InkWell(
                  onTap: canSetDefault ? () => _setDefaultResume(resume) : null,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        resume.isDefault
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: resume.isDefault
                            ? const Color(0xFF096DD9)
                            : const Color(0xFFBFBFBF),
                      ),
                      SizedBox(width: 7),
                      Text(
                        isSettingDefault
                            ? '设置中...'
                            : (resume.isDefault ? '已设默认' : '设为默认'),
                        style: const TextStyle(
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
                Text(
                  resume.isPublic ? '可见' : '隐藏',
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: resume.isPublic,
                  onChanged: isSavingVisibility
                      ? null
                      : (bool value) => _updateResumeVisibility(resume, value),
                  activeThumbColor: Colors.white,
                  activeTrackColor: const Color(0xFF096DD9),
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: const Color(0xFFD9D9D9),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 构建管理态下的底部操作区。
  Widget _buildManageActions({
    required ResumeListItemVO resume,
    required bool isSettingDefault,
    required bool isDeleting,
    required bool canSetDefault,
  }) {
    return Row(
      children: <Widget>[
        InkWell(
          onTap: canSetDefault ? () => _setDefaultResume(resume) : null,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: <Widget>[
                Icon(
                  resume.isDefault
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 20,
                  color: resume.isDefault
                      ? const Color(0xFF096DD9)
                      : const Color(0xFFBFBFBF),
                ),
                SizedBox(width: 7),
                Text(
                  isSettingDefault
                      ? '设置中...'
                      : (resume.isDefault ? '已设默认' : '设为默认'),
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: isDeleting ? null : () => _deleteResume(resume),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: Color(0xFFD9363E),
                ),
                const SizedBox(width: 4),
                Text(
                  isDeleting ? '删除中...' : '删除简历',
                  style: const TextStyle(
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
            onPressed: _isCreatingResume ? null : _openCreateResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF096DD9),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _isCreatingResume ? '创建中...' : '创建简历',
              style: const TextStyle(
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
    if (_isCreatingResume) {
      return;
    }

    setState(() {
      _isCreatingResume = true;
    });

    try {
      final int resumeId = await ref.read(resumeServiceProvider).createResume();
      if (!mounted) {
        return;
      }

      setState(() {
        _isCreatingResume = false;
      });

      await context.push<bool>(
        RoutePaths.myResumeEditor,
        extra: ResumeEditorArgs.create(
          isPublic: _defaultCreateVisibility,
          resumeId: resumeId,
        ),
      );
      if (!mounted) {
        return;
      }
      await _loadResume();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCreatingResume = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    }
  }

  /// 进入编辑简历页，并按卡片对应的 `resumeId` 拉取完整详情。
  Future<void> _openResumeEditor(ResumeListItemVO resume) async {
    try {
      final ResumeVO latestResume = await ref
          .read(resumeServiceProvider)
          .getResumeDetail(resumeId: resume.resumeId);
      if (!mounted) {
        return;
      }

      final bool? didSave = await context.push<bool>(
        RoutePaths.myResumeEditor,
        extra: ResumeEditorArgs.edit(latestResume),
      );
      if (didSave == true && mounted) {
        await _loadResume();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    }
  }

  /// 切换简历公开状态，并通过保存接口同步到服务端。
  Future<void> _updateResumeVisibility(ResumeListItemVO resume, bool value) async {
    if (_savingVisibilityResumeId != null) {
      return;
    }

    setState(() {
      _savingVisibilityResumeId = resume.resumeId;
    });

    try {
      final service = ref.read(resumeServiceProvider);
      final ResumeVO detail = await service.getResumeDetail(resumeId: resume.resumeId);
      await service.updateResume(
        resumeId: resume.resumeId,
        request: detail.toSaveResumeBO(isPublic: value),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _savingVisibilityResumeId = null;
        _resumes = _resumes
            .map(
              (item) => item.resumeId == resume.resumeId
                  ? ResumeListItemVO(
                      resumeId: item.resumeId,
                      isDefault: item.isDefault,
                      completeness: item.completeness,
                      targetPositions: item.targetPositions,
                      targetCountries: item.targetCountries,
                      isPublic: value,
                      updatedAt: item.updatedAt,
                      nickname: item.nickname,
                      avatarUrl: item.avatarUrl,
                      gender: item.gender,
                      age: item.age,
                      currentLocation: item.currentLocation,
                      salaryMin: item.salaryMin,
                      salaryMax: item.salaryMax,
                      salaryCurrency: item.salaryCurrency,
                      latestExperience: item.latestExperience,
                    )
                  : item,
            )
            .toList(growable: false);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(value ? '已设为可见' : '已设为不可见')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingVisibilityResumeId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    }
  }

  /// 将当前简历设为默认简历，并在成功后刷新本地详情。
  Future<void> _setDefaultResume(ResumeListItemVO resume) async {
    if (_settingDefaultResumeId != null || resume.isDefault) {
      return;
    }

    setState(() {
      _settingDefaultResumeId = resume.resumeId;
    });

    try {
      final service = ref.read(resumeServiceProvider);
      await service.setDefaultResume(resumeId: resume.resumeId);
      if (!mounted) {
        return;
      }
      setState(() {
        _settingDefaultResumeId = null;
      });
      await _loadResume();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已设为默认简历')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _settingDefaultResumeId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    }
  }

  /// 删除当前简历，并在成功后从本地移除卡片。
  Future<void> _deleteResume(ResumeListItemVO resume) async {
    if (_deletingResumeId != null) {
      return;
    }

    setState(() {
      _deletingResumeId = resume.resumeId;
    });

    try {
      await ref
          .read(resumeServiceProvider)
          .deleteResume(resumeId: resume.resumeId);
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingResumeId = null;
      });
      await _loadResume();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('简历已删除')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deletingResumeId = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_resolveErrorMessage(error))));
    }
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
    required this.salary,
    required this.jobTitle,
    required this.duration,
    required this.summary,
    required this.avatarUrl,
    required this.avatarFallbackText,
  });

  final String name;
  final String region;
  final String age;
  final String gender;
  final String salary;
  final String jobTitle;
  final String duration;
  final String summary;
  final String avatarUrl;
  final String avatarFallbackText;
}

extension on _MyResumePageState {
  bool get _defaultCreateVisibility {
    for (final ResumeListItemVO item in _resumes) {
      if (item.isDefault) {
        return item.isPublic;
      }
    }
    return true;
  }

  String _buildAvatarFallbackText(String nickname) {
    final String trimmed = nickname.trim();
    if (trimmed.isEmpty) {
      return '简历';
    }
    return trimmed.characters.take(2).toString();
  }

  String _formatSalaryText(ResumeListItemVO item) {
    final double? min = item.salaryMin;
    final double? max = item.salaryMax;
    if ((min == null || min <= 0) && (max == null || max <= 0)) {
      return '薪资待完善';
    }
    final String currency = item.salaryCurrency.trim().isEmpty
        ? ''
        : '${item.salaryCurrency.trim()} ';
    if (max != null && max > 0) {
      return '$currency${_formatNullableDouble(min)}-${_formatNullableDouble(max)}';
    }
    return '$currency${_formatNullableDouble(min)}';
  }

  String _formatNullableDouble(double? value) {
    if (value == null || value <= 0) {
      return '0';
    }
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

extension on ResumeVO {

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
}
