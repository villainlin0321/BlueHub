import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';

/// 企业岗位页。
class CompanyVisaPage extends StatefulWidget {
  const CompanyVisaPage({super.key});

  @override
  State<CompanyVisaPage> createState() => _CompanyVisaPageState();
}

class _CompanyVisaPageState extends State<CompanyVisaPage> {
  int _tabIndex = 0;

  static const List<String> _tabs = <String>['招聘中', '已下线'];

  static const List<_JobManageCardData> _recruitingJobs = <_JobManageCardData>[
    _JobManageCardData(
      title: '中餐头灶 (包食宿)',
      tags: <String>['3-5年经验', '德国·柏林', '提供签证'],
      salary: '€2,500~3,500/月',
      viewsText: '浏览 342',
      resumesText: '收到简历 24',
    ),
    _JobManageCardData(
      title: '中餐面点 (包食宿)',
      tags: <String>['3-5年经验', '德国·柏林', '提供签证'],
      salary: '€2,500~3,500/月',
      viewsText: '浏览 342',
      resumesText: '收到简历 24',
    ),
    _JobManageCardData(
      title: '中餐切配 (包食宿)',
      tags: <String>['3-5年经验', '德国·柏林', '提供签证文字太长太长太长太长太长太长...'],
      salary: '€2,500~3,500/月',
      viewsText: '浏览 342',
      resumesText: '收到简历 24',
    ),
    _JobManageCardData(
      title: '凉菜师傅 (包食宿)',
      tags: <String>['3-5年经验', '德国·柏林', '提供签证'],
      salary: '€2,500~3,500/月',
      viewsText: '浏览 342',
      resumesText: '收到简历 24',
    ),
  ];

  static const List<_JobManageCardData> _offlineJobs = <_JobManageCardData>[
    _JobManageCardData(
      title: '凉菜师傅 (包食宿)',
      tags: <String>['3-5年经验', '德国·柏林', '提供签证'],
      salary: '€2,500~3,500/月',
      viewsText: '浏览 186',
      resumesText: '收到简历 12',
      isOffline: true,
    ),
    _JobManageCardData(
      title: '中餐切配 (包食宿)',
      tags: <String>['3-5年经验', '德国·柏林', '提供签证'],
      salary: '€2,500~3,500/月',
      viewsText: '浏览 210',
      resumesText: '收到简历 16',
      isOffline: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final List<_JobManageCardData> jobs = _tabIndex == 0
        ? _recruitingJobs
        : _offlineJobs;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _CompanyVisaHeader(
            topPadding: topPadding,
            onPublishTap: () => context.push(RoutePaths.postJob),
          ),
          _CompanyVisaTabBar(
            selectedIndex: _tabIndex,
            onTap: (int index) {
              setState(() {
                _tabIndex = index;
              });
            },
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: jobs.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                return _JobManageCard(data: jobs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyVisaHeader extends StatelessWidget {
  const _CompanyVisaHeader({
    required this.topPadding,
    required this.onPublishTap,
  });

  final double topPadding;
  final VoidCallback onPublishTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      child: Row(
        children: <Widget>[
          const Spacer(),
          const Text(
            '岗位',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onPublishTap,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Text(
                '发布',
                style: TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 15,
                  height: 21 / 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyVisaTabBar extends StatelessWidget {
  const _CompanyVisaTabBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List<Widget>.generate(_CompanyVisaPageState._tabs.length, (
          int index,
        ) {
          final bool selected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              onTap: () => onTap(index),
              child: Padding(
                padding: EdgeInsets.only(top: 11, bottom: selected ? 0 : 11),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      _CompanyVisaPageState._tabs[index],
                      style: TextStyle(
                        color: selected
                            ? const Color(0xFF096DD9)
                            : const Color(0xFF262626),
                        fontSize: 14,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        height: 22 / 14,
                      ),
                    ),
                    if (selected) ...<Widget>[
                      const SizedBox(height: 9),
                      Container(
                        width: 20,
                        height: 2,
                        color: const Color(0xFF096DD9),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _JobManageCard extends StatelessWidget {
  const _JobManageCard({required this.data});

  final _JobManageCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    data.title,
                    style: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                    ),
                  ),
                ),
                const _MoreActionIcon(),
              ],
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: data.tags
                    .map(
                      (String tag) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: _JobTag(label: tag),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Text(
                  data.salary,
                  style: const TextStyle(
                    color: Color(0xFFFE5815),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 24 / 14,
                  ),
                ),
                const Spacer(),
                Text(
                  data.viewsText,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 18 / 12,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  data.resumesText,
                  style: const TextStyle(
                    color: Color(0xFF096DD9),
                    fontSize: 12,
                    height: 18 / 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                const _DeleteActionButton(),
                const Spacer(),
                _BorderActionButton(label: data.isOffline ? '发布' : '下线'),
                const SizedBox(width: 8),
                const _PrimaryActionButton(label: '编辑'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JobTag extends StatelessWidget {
  const _JobTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 10,
          height: 10 / 10,
        ),
      ),
    );
  }
}

class _MoreActionIcon extends StatelessWidget {
  const _MoreActionIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: Color(0xFF171A1D),
        ),
      ),
    );
  }
}

class _DeleteActionButton extends StatelessWidget {
  const _DeleteActionButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF4D4F)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const Text(
        '删除',
        style: TextStyle(
          color: Color(0xFFD9363E),
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _BorderActionButton extends StatelessWidget {
  const _BorderActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF262626),
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 26),
      decoration: BoxDecoration(
        color: const Color(0xFF096DD9),
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _JobManageCardData {
  const _JobManageCardData({
    required this.title,
    required this.tags,
    required this.salary,
    required this.viewsText,
    required this.resumesText,
    this.isOffline = false,
  });

  final String title;
  final List<String> tags;
  final String salary;
  final String viewsText;
  final String resumesText;
  final bool isOffline;
}
