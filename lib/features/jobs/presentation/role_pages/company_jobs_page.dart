import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 企业招聘页：按 Figma「人才中心」实现。
class CompanyJobsPage extends StatefulWidget {
  const CompanyJobsPage({super.key});

  @override
  State<CompanyJobsPage> createState() => _CompanyJobsPageState();
}

class _CompanyJobsPageState extends State<CompanyJobsPage> {
  int _selectedTabIndex = 0;

  static const List<String> _tabs = <String>['全部人才', '近期活跃', '高匹配度', '厨师岗位'];

  static const List<_CandidateCardData> _candidates = <_CandidateCardData>[
    _CandidateCardData(
      avatarAssetPath: 'assets/images/mou52cw6-js17mxu.png',
      name: '万先生',
      ageGender: '32岁·男',
      intention: '意向：德国/中餐厨师',
      matchRate: '92%',
      tags: <String>['3年经验', '厨师证高级', '随时到岗'],
      activeText: '2小时前活跃',
    ),
    _CandidateCardData(
      avatarAssetPath: 'assets/images/mou52cw6-js17mxu.png',
      name: '万先生',
      ageGender: '32岁·男',
      intention: '意向：德国·柏林/中餐厨师',
      matchRate: '92%',
      tags: <String>['3年经验', '厨师证高级', '随时到岗'],
      activeText: '2小时前活跃',
    ),
    _CandidateCardData(
      avatarAssetPath: 'assets/images/mou52cw6-js17mxu.png',
      name: '万先生',
      ageGender: '32岁·男',
      intention: '意向：德国·柏林/中餐厨师',
      matchRate: '92%',
      tags: <String>['3年经验', '厨师证高级', '随时到岗'],
      activeText: '2小时前活跃',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      children: <Widget>[
        _Header(topPadding: topPadding),
        const _SearchBar(),
        _TabBarSection(
          selectedIndex: _selectedTabIndex,
          onTap: (int index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        ),
        const _AiBanner(),
        Padding(
          padding: const EdgeInsets.fromLTRB(11, 12, 14, 0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _candidates.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (BuildContext context, int index) {
              return _CandidateCard(data: _candidates[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, topPadding + 10, 16, 10),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '人才中心',
              style: TextStyle(
                color: Color(0xE6000000),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '筛选',
              style: TextStyle(
                color: Color(0xFF262626),
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 21 / 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            SvgPicture.asset(
              'assets/images/mou52cw6-pzdc72z.svg',
              width: 16,
              height: 16,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '搜索岗位/技能/经验',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Color(0xFFBFBFBF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBarSection extends StatelessWidget {
  const _TabBarSection({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List<Widget>.generate(_CompanyJobsPageState._tabs.length, (
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
                      _CompanyJobsPageState._tabs[index],
                      textAlign: TextAlign.center,
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

class _AiBanner extends StatelessWidget {
  const _AiBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SvgPicture.asset(
                'assets/images/mou52cw6-a9gamk4.svg',
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    'assets/images/mou52cw6-nklu474.png',
                    width: 40,
                    height: 40,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          'AI业务助手',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                            height: 22 / 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '为您精准推荐 5 名资深中餐厨师',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            height: 16 / 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BannerAction(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerAction extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 28,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  '查看',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 12 / 12,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 2),
                Image.asset(
                  'assets/images/mou52cw6-bqoy994.png',
                  width: 12,
                  height: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.data});

  final _CandidateCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child:           Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Image.asset(data.avatarAssetPath, width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            data.name,
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 24 / 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            data.ageGender,
                            style: const TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.intention,
                        style: const TextStyle(
                          color: Color(0xFF595959),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: <Widget>[
                    Text(
                      data.matchRate,
                      style: const TextStyle(
                        color: Color(0xFF096DD9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 21 / 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      '匹配',
                      style: TextStyle(
                        color: Color(0xFF096DD9),
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 14 / 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.tags
                  .map((String tag) => _CandidateTag(label: tag))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Text(
                  data.activeText,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
                const Spacer(),
                const _ResumeActionButton(label: '查看简历', primary: false),
                const SizedBox(width: 8),
                const _ResumeActionButton(label: '邀约面试', primary: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateTag extends StatelessWidget {
  const _CandidateTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4), width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class _ResumeActionButton extends StatelessWidget {
  const _ResumeActionButton({required this.label, required this.primary});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? const Color(0xFF096DD9) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: primary
            ? null
            : Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: primary ? Colors.white : const Color(0xFF262626),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _CandidateCardData {
  const _CandidateCardData({
    required this.avatarAssetPath,
    required this.name,
    required this.ageGender,
    required this.intention,
    required this.matchRate,
    required this.tags,
    required this.activeText,
  });

  final String avatarAssetPath;
  final String name;
  final String ageGender;
  final String intention;
  final String matchRate;
  final List<String> tags;
  final String activeText;
}
