import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/job_position_card.dart';

/// 求职者招聘页：严格按 Figma 还原搜索、筛选和职位列表。
class JobSeekerJobsPage extends StatelessWidget {
  const JobSeekerJobsPage({super.key});

  static const List<_JobCardItem> _jobs = <_JobCardItem>[
    _JobCardItem(
      data: JobPositionCardData(
        title: '中餐厨师 (包食宿)',
        salary: '€2,500~3,500',
        requirementTags: <String>['3-5年经验', '厨师证高级', '提供签证'],
        highlightTags: <String>['急招', '包吃住'],
        company: '柏林老四川餐厅',
        location: '德国·柏林',
        companyAvatarAssetPath: 'assets/images/mou2x9mw-w0z6m1f.png',
        locationIconAssetPath: 'assets/images/mou2x9mw-vdptc5a.svg',
        showApplyButton: true,
      ),
      navigateToDetail: true,
    ),
    _JobCardItem(
      data: JobPositionCardData(
        title: '建筑工(包食宿)',
        salary: '€2,200~2,800',
        requirementTags: <String>['3-5年经验', '不限学历', '包食宿'],
        highlightTags: <String>['年假回国机票'],
        company: '柏林老四川餐厅',
        location: '德国·柏林',
        companyAvatarAssetPath: 'assets/images/mou2x9mw-w0z6m1f.png',
        locationIconAssetPath: 'assets/images/mou2x9mw-i9nkf4t.svg',
        showApplyButton: true,
      ),
    ),
    _JobCardItem(
      data: JobPositionCardData(
        title: '中餐帮厨',
        salary: '€1,500~2,000',
        requirementTags: <String>['3-5年经验', '厨师证', '提供签证'],
        highlightTags: <String>['双休'],
        company: '柏林老四川餐厅',
        location: '德国·柏林',
        companyAvatarAssetPath: 'assets/images/mou2x9mw-w0z6m1f.png',
        locationIconAssetPath: 'assets/images/mou2x9mw-i9nkf4t.svg',
        showApplyButton: true,
      ),
    ),
    _JobCardItem(
      data: JobPositionCardData(
        title: '养老院护理员',
        salary: '€2,000~2.500',
        requirementTags: <String>['3-5年经验', '营养健康证', '提供签证'],
        highlightTags: <String>['长白班'],
        company: '柏林老四川餐厅',
        location: '德国·柏林',
        companyAvatarAssetPath: 'assets/images/mou2x9mw-w0z6m1f.png',
        locationIconAssetPath: 'assets/images/mou2x9mw-i9nkf4t.svg',
        showApplyButton: true,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.only(bottom: bottomPadding + 24),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              '欧洲招聘',
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _JobsSearchBar(),
          ),
          const SizedBox(height: 13),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _FilterRow(),
          ),
          const SizedBox(height: 19),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _jobs.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final _JobCardItem item = _jobs[index];
                return JobPositionCard(
                  data: item.data,
                  onTap: () {
                    if (item.navigateToDetail) {
                      context.push(RoutePaths.jobDetail);
                      return;
                    }
                    _showPlaceholderMessage(context);
                  },
                  onApply: () => _showPlaceholderMessage(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static void _showPlaceholderMessage(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('功能开发中')));
  }
}

class _JobsSearchBar extends StatelessWidget {
  const _JobsSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: <Widget>[
          AppSvgIcon(
            assetPath: 'assets/images/mou2x9mw-2jfef5b.svg',
            fallback: Icons.search_rounded,
            size: 16,
            color: Color(0xFFBFBFBF),
          ),
          SizedBox(width: 8),
          Text(
            '搜索签证服务/欧洲岗位',
            style: TextStyle(
              color: Color(0xFFBFBFBF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _DropdownChip(
          label: '全部国家',
          iconAssetPath: 'assets/images/mou2x9mw-y3xkvto.png',
          width: 88,
        ),
        _DropdownChip(
          label: '全部分类',
          iconAssetPath: 'assets/images/mou2x9mw-y3xkvto.png',
          width: 88,
        ),
        _DropdownChip(
          label: '薪资要求',
          iconAssetPath: 'assets/images/mou2x9mw-flxj53h.png',
          width: 88,
          highlighted: true,
        ),
        _FilterActionChip(),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.iconAssetPath,
    required this.width,
    this.highlighted = false,
  });

  final String label;
  final String iconAssetPath;
  final double width;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = highlighted
        ? const Color(0xFF096DD9)
        : Colors.transparent;
    final Color textColor = highlighted
        ? const Color(0xFF096DD9)
        : const Color(0xFF171A1D);

    return Container(
      width: width,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: highlighted ? FontWeight.w500 : FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Image.asset(
            iconAssetPath,
            width: 12,
            height: 12,
            errorBuilder: (_, __, ___) {
              return Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: textColor,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterActionChip extends StatelessWidget {
  const _FilterActionChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '筛选',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 18 / 12,
              ),
            ),
          ),
          SizedBox(width: 4),
          AppSvgIcon(
            assetPath: 'assets/images/mou2x9mw-6xvx4hp.svg',
            fallback: Icons.tune_rounded,
            size: 12,
            color: Color(0xFF171A1D),
          ),
        ],
      ),
    );
  }
}

class _JobCardItem {
  const _JobCardItem({required this.data, this.navigateToDetail = false});

  final JobPositionCardData data;
  final bool navigateToDetail;
}
