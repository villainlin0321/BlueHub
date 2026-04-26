import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import 'my_resume_editor_page.dart';

/// 我的简历页。
///
/// 这里先按设计稿实现静态展示与本地交互：
/// 1. 支持切换默认展示简历。
/// 2. 支持切换首份简历的“可见”开关。
/// 3. 支持进入管理态，展示卡片管理操作。
/// 4. 支持弹出删除确认弹窗并执行本地删除。
/// 5. 底部“创建简历”按钮先保留占位提示。
class MyResumePage extends StatefulWidget {
  const MyResumePage({super.key});

  @override
  State<MyResumePage> createState() => _MyResumePageState();
}

class _MyResumePageState extends State<MyResumePage> {
  static const List<_ResumeItemData> _initialResumeItems = <_ResumeItemData>[
    _ResumeItemData(
      name: '程先生',
      region: '德国',
      age: '32岁',
      gender: '男',
      phone: '189****8655',
      salary: '1,500-2,000',
      jobTitle: '伦敦康诺特酒店·高级电工',
      duration: '2016-至今',
      summary: '从事电气技术工作8年，持高级电工证，擅长工业电气系统安装调试、设备维护升级、配电方案优化及安全管理…',
      avatarColor: Color(0xFF8FB6FF),
      avatarIcon: Icons.person,
    ),
    _ResumeItemData(
      name: '程先生',
      region: '德国',
      age: '32岁',
      gender: '男',
      phone: '189****8655',
      salary: '1,500-2,000',
      jobTitle: '伦敦康诺特酒店·高级电工',
      duration: '2016-至今',
      summary: '从事电气技术工作8年，持高级电工证，持有海外酒店维修经验，熟悉设备点检和安全规范执行…',
      avatarColor: Color(0xFFB4D7FF),
      avatarIcon: Icons.face_rounded,
    ),
    _ResumeItemData(
      name: '程先生',
      region: '德国',
      age: '32岁',
      gender: '男',
      phone: '189****8655',
      salary: '1,500-2,000',
      jobTitle: '伦敦康诺特酒店·高级电工',
      duration: '2016-至今',
      summary: '从事电气技术工作8年，持高级电工证，擅长工业电气系统安装调试、设备维护升级及安全管理…',
      avatarColor: Color(0xFF9EC2FF),
      avatarIcon: Icons.person,
    ),
  ];

  late final List<_ResumeItemData> _resumeItems = List<_ResumeItemData>.of(
    _initialResumeItems,
  );
  int _defaultResumeIndex = 0;
  bool _isFirstResumeVisible = true;
  bool _isManaging = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(context),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomAction(context),
    );
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

  /// 构建页面主体内容，包含说明文案和简历卡片列表。
  Widget _buildBody() {
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
        if (_resumeItems.isEmpty)
          _buildEmptyState()
        else
          for (var index = 0; index < _resumeItems.length; index++) ...<Widget>[
            _buildResumeCard(index, _resumeItems[index]),
            if (index != _resumeItems.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }

  /// 构建单张简历卡片。
  Widget _buildResumeCard(int index, _ResumeItemData item) {
    final bool isDefault = _defaultResumeIndex == index;
    final bool showVisibilitySwitch = index == 0;

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
            onTap: _isManaging ? null : () => _openResumeEditor(item),
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
            _buildManageActions(index)
          else
            Row(
              children: <Widget>[
                InkWell(
                  onTap: () {
                    // 点击任一简历的底部单选区时，切换当前默认展示简历。
                    setState(() => _defaultResumeIndex = index);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isDefault
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 20,
                        color: isDefault
                            ? const Color(0xFF096DD9)
                            : const Color(0xFFBFBFBF),
                      ),
                      const SizedBox(width: 7),
                      const Text(
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
                if (showVisibilitySwitch) ...<Widget>[
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
                      value: _isFirstResumeVisible,
                      onChanged: (value) {
                        // 设计稿只有首张卡片展示可见开关，这里保持同样的结构。
                        setState(() => _isFirstResumeVisible = value);
                      },
                      activeThumbColor: Colors.white,
                      activeTrackColor: const Color(0xFF096DD9),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(0xFFD9D9D9),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  /// 构建管理态下的卡片底部操作区。
  Widget _buildManageActions(int index) {
    final bool isDefault = _defaultResumeIndex == index;

    return Row(
      children: <Widget>[
        InkWell(
          onTap: () {
            // 管理态下仍允许切换默认简历，保持与设计稿左侧勾选区一致。
            setState(() => _defaultResumeIndex = index);
          },
          borderRadius: BorderRadius.circular(10),
          child: Row(
            children: <Widget>[
              Icon(
                isDefault
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isDefault
                    ? const Color(0xFF096DD9)
                    : const Color(0xFFBFBFBF),
              ),
              const SizedBox(width: 7),
              const Text(
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
        InkWell(
          onTap: () => _showDeleteDialog(index),
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

  /// 构建空状态，占位处理全部删除后的页面反馈。
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
  void _openCreateResume() {
    context.push(
      RoutePaths.myResumeEditor,
      extra: const ResumeEditorArgs.create(),
    );
  }

  /// 进入编辑简历页，并把当前卡片数据带入表单。
  void _openResumeEditor(_ResumeItemData item) {
    context.push(
      RoutePaths.myResumeEditor,
      extra: ResumeEditorArgs.edit(
        ResumeDraft(
          name: item.name,
          region: item.region,
          age: item.age,
          gender: item.gender,
          phone: item.phone,
          salary: item.salary,
          jobTitle: item.jobTitle,
          duration: item.duration,
          summary: item.summary,
        ),
      ),
    );
  }

  /// 弹出删除确认弹窗，并在确认后移除本地列表项。
  Future<void> _showDeleteDialog(int index) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 49),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 276,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  '确认删除吗？',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '删除简历后将不可恢复',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    SizedBox(
                      width: 100,
                      height: 36,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF262626),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFD9D9D9)),
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 112,
                      height: 36,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD9363E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          '确认删除',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 20 / 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    setState(() {
      // 删除后同步修正默认简历索引，避免越界。
      _resumeItems.removeAt(index);
      if (_resumeItems.isEmpty) {
        _defaultResumeIndex = 0;
        _isManaging = false;
        return;
      }
      if (_defaultResumeIndex > index) {
        _defaultResumeIndex -= 1;
      } else if (_defaultResumeIndex >= _resumeItems.length) {
        _defaultResumeIndex = _resumeItems.length - 1;
      }
    });
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
