import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/widgets/app_svg_icon.dart';

/// 企业首页。
class CompanyHomePage extends ConsumerWidget {
  const CompanyHomePage({super.key});

  static const List<_QuickActionItem> _quickActions = <_QuickActionItem>[
    _QuickActionItem(
      label: '发布招聘',
      assetPath: 'assets/images/mon6z4rt-qet9p7k.svg',
      fallback: Icons.add_business_outlined,
    ),
    _QuickActionItem(
      label: '人才中心',
      assetPath: 'assets/images/mon6z4rt-vvh6pmo.svg',
      fallback: Icons.school_outlined,
    ),
    _QuickActionItem(
      label: '应聘管理',
      assetPath: 'assets/images/mon6z4ru-nlqxve0.svg',
      fallback: Icons.assignment_ind_outlined,
      routePath: RoutePaths.companyApplications,
    ),
    _QuickActionItem(
      label: '签证服务',
      assetPath: 'assets/images/mon6z4rt-44w61yz.svg',
      fallback: Icons.assignment_outlined,
    ),
  ];

  static const List<_ResumeCardItem> _resumeItems = <_ResumeCardItem>[
    _ResumeCardItem(
      name: '万先生',
      ageGender: '32岁·男',
      appliedJob: '应聘：中餐厨师',
      matchPercent: '85%',
      tags: <String>['5年经验', '高级厨师证', '随时到岗'],
      deliveryTime: '昨日14:40投递',
    ),
    _ResumeCardItem(
      name: '万先生',
      ageGender: '32岁·男',
      appliedJob: '应聘：中餐厨师',
      matchPercent: '85%',
      tags: <String>['5年经验', '高级厨师证', '随时到岗'],
      deliveryTime: '昨日14:40投递',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomPadding + 94),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _HeroSection(),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _QuickActionRow(items: _quickActions),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _AiAssistantBanner(),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 11),
            child: _ResumeSectionHeader(),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _resumeItems.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final _ResumeCardItem item = _resumeItems[index];
                return _ResumeCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF3F9BF7), Color(0xFF2F73E5)],
        ),
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -36,
            top: -36,
            child: Container(
              width: 156,
              height: 156,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFF1FDAFF), Color(0x003584EC)],
                ),
              ),
            ),
          ),
          Positioned(
            right: -52,
            bottom: -56,
            child: Container(
              width: 168,
              height: 168,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: <Color>[Color(0xFF456DFF), Color(0x003584EC)],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, topPadding + 10, 14, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const <Widget>[
                _CompanyHeroTopRow(),
                SizedBox(height: 18),
                _CompanyHeroStatsRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeroTopRow extends StatelessWidget {
  const _CompanyHeroTopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                '企',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      '柏林老四川餐厅',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 20 / 17,
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  _EnterpriseBadge(),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(
                    '餐饮行业',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 14 / 11,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '德国·柏林',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      height: 14 / 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _HeroMessageButton(),
      ],
    );
  }
}

class _EnterpriseBadge extends StatelessWidget {
  const _EnterpriseBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFFFED86B),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        '企',
        style: TextStyle(
          color: Color(0xFF6F4200),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

class _HeroMessageButton extends StatelessWidget {
  const _HeroMessageButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned.fill(
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          Positioned(
            top: 1,
            right: -1,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFF24C3D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyHeroStatsRow extends StatelessWidget {
  const _CompanyHeroStatsRow();

  static const List<_HeroStatItem> _items = <_HeroStatItem>[
    _HeroStatItem(value: '8', label: '在招岗位'),
    _HeroStatItem(value: '108', label: '收到简历'),
    _HeroStatItem(value: '13', label: '待面试'),
    _HeroStatItem(value: '4', label: '已录用'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items
          .map(
            (item) => Expanded(
              child: Column(
                children: <Widget>[
                  Text(
                    item.value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 24 / 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      height: 16 / 12,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _HeroStatItem {
  const _HeroStatItem({required this.value, required this.label});

  final String value;
  final String label;
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.items});

  final List<_QuickActionItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map((item) => _QuickActionButton(item: item))
          .toList(growable: false),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({required this.item});

  final _QuickActionItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: item.routePath == null
            ? null
            : () => context.push(item.routePath!),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFEBF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: AppSvgIcon(
                  assetPath: item.assetPath,
                  fallback: item.fallback,
                  size: 24,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF171A1D),
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAssistantBanner extends StatelessWidget {
  const _AiAssistantBanner();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: SvgPicture.asset(
            'assets/images/mon6z4rt-nbxozyy.svg',
            fit: BoxFit.fill,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
          child: Row(
            children: <Widget>[
              Image.asset(
                'assets/images/mon6z4rt-kh50fma.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'AI业务助手',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 22 / 15,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '为您精准推荐 5 名资深中餐厨师',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 16 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Text(
                      '查看',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 12 / 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Image.asset(
                      'assets/images/mon6z4rt-3ivopc0.png',
                      width: 12,
                      height: 12,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumeSectionHeader extends StatelessWidget {
  const _ResumeSectionHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            '最新收到简历',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
        ),
        const Text(
          '全部',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
        const SizedBox(width: 2),
        Image.asset(
          'assets/images/mon6z4rt-eqk5cki.png',
          width: 16,
          height: 16,
        ),
      ],
    );
  }
}

class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.item});

  final _ResumeCardItem item;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Image.asset(
                  'assets/images/mon6z4rt-xyu3wvu.png',
                  width: 40,
                  height: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            item.name,
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.ageGender,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 12,
                              height: 18 / 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.appliedJob,
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 12,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    children: <InlineSpan>[
                      TextSpan(
                        text: item.matchPercent,
                        style: const TextStyle(
                          color: Color(0xFF096DD9),
                          fontSize: 16,
                          height: 21 / 16,
                        ),
                      ),
                      const TextSpan(
                        text: ' 匹配',
                        style: TextStyle(
                          color: Color(0xFF096DD9),
                          fontSize: 10,
                          height: 14 / 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: item.tags
                  .map((tag) => _SkillTag(label: tag))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  item.deliveryTime,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
                const Spacer(),
                const _GhostActionButton(label: '查看简历'),
                const SizedBox(width: 8),
                const _PrimaryActionButton(label: '邀约面试'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTag extends StatelessWidget {
  const _SkillTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 11,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class _GhostActionButton extends StatelessWidget {
  const _GhostActionButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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

class _QuickActionItem {
  const _QuickActionItem({
    required this.label,
    required this.assetPath,
    required this.fallback,
    this.routePath,
  });

  final String label;
  final String assetPath;
  final IconData fallback;
  final String? routePath;
}

class _ResumeCardItem {
  const _ResumeCardItem({
    required this.name,
    required this.ageGender,
    required this.appliedJob,
    required this.matchPercent,
    required this.tags,
    required this.deliveryTime,
  });

  final String name;
  final String ageGender;
  final String appliedJob;
  final String matchPercent;
  final List<String> tags;
  final String deliveryTime;
}
