import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/talent_providers.dart';
import '../../../../shared/network/models/talent_models.dart';

/// 企业招聘页：按 Figma「人才中心」实现。
class CompanyJobsPage extends ConsumerStatefulWidget {
  const CompanyJobsPage({super.key});

  @override
  ConsumerState<CompanyJobsPage> createState() => _CompanyJobsPageState();
}

class _CompanyJobsPageState extends ConsumerState<CompanyJobsPage> {
  int _selectedTabIndex = 0;

  static const List<String> _tabs = <String>['全部人才', '近期活跃', '高匹配度', '厨师岗位'];

  late final TextEditingController _searchController = TextEditingController()
    ..addListener(_handleSearchChanged);

  String? get _keyword {
    final String value = _searchController.text.trim();
    return value.isEmpty ? null : value;
  }

  String? get _selectedPosition =>
      _selectedTabIndex == 3 ? '中餐厨师' : null;

  TalentListQuery get _query => TalentListQuery(
    keyword: _keyword,
    position: _selectedPosition,
    page: 1,
    pageSize: 20,
  );

  void _handleSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final talentsAsync = ref.watch(talentListProvider(_query));

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      children: <Widget>[
        _Header(topPadding: topPadding),
        _SearchBar(controller: _searchController),
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
          child: talentsAsync.when(
            data: (pageResult) {
              if (pageResult.list.isEmpty) {
                return const _TalentsEmptyState();
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pageResult.list.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  return _CandidateCard(
                    data: _CandidateCardData.fromTalent(pageResult.list[index]),
                  );
                },
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => _TalentLoadError(
              onRetry: () {
                ref.invalidate(talentListProvider(_query));
              },
            ),
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
  const _SearchBar({required this.controller});

  final TextEditingController controller;

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
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '搜索岗位/技能/经验',
                  hintStyle: TextStyle(
                    color: Color(0xFFBFBFBF),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
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
                _CandidateAvatar(avatarUrl: data.avatarUrl),
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
                      data.scoreText,
                      style: const TextStyle(
                        color: Color(0xFF096DD9),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 21 / 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data.scoreLabel,
                      style: const TextStyle(
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
                  data.updatedText,
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
    required this.avatarUrl,
    required this.name,
    required this.ageGender,
    required this.intention,
    required this.scoreText,
    required this.scoreLabel,
    required this.tags,
    required this.updatedText,
  });

  final String avatarUrl;
  final String name;
  final String ageGender;
  final String intention;
  final String scoreText;
  final String scoreLabel;
  final List<String> tags;
  final String updatedText;

  factory _CandidateCardData.fromTalent(TalentVO talent) {
    return _CandidateCardData(
      avatarUrl: talent.avatarUrl,
      name: talent.nickname.isEmpty ? '未命名用户' : talent.nickname,
      ageGender: _buildAgeGender(talent),
      intention: _buildIntention(talent),
      scoreText: '${talent.completeness}%',
      scoreLabel: '完整度',
      tags: _buildTags(talent),
      updatedText: _buildUpdatedText(talent.updatedAt),
    );
  }

  static String _buildAgeGender(TalentVO talent) {
    final List<String> parts = <String>[];
    if (talent.age != null) {
      parts.add('${talent.age}岁');
    }
    final String genderText = switch (talent.gender.trim().toLowerCase()) {
      'male' => '男',
      'female' => '女',
      _ => '',
    };
    if (genderText.isNotEmpty) {
      parts.add(genderText);
    }
    return parts.isEmpty ? '信息待完善' : parts.join('·');
  }

  static String _buildIntention(TalentVO talent) {
    final String countries = talent.targetCountries.join(' / ');
    final String positions = talent.targetPositions.join(' / ');
    if (countries.isEmpty && positions.isEmpty) {
      return '意向：待完善';
    }
    if (countries.isEmpty) {
      return '意向：$positions';
    }
    if (positions.isEmpty) {
      return '意向：$countries';
    }
    return '意向：$countries / $positions';
  }

  static List<String> _buildTags(TalentVO talent) {
    final List<String> tags = <String>[];
    if (talent.yearsOfExperience > 0) {
      tags.add('${talent.yearsOfExperience}年经验');
    }
    if (talent.targetPositions.isNotEmpty) {
      tags.add(talent.targetPositions.first);
    }
    if (talent.targetCountries.isNotEmpty) {
      tags.add(talent.targetCountries.first);
    }
    if (tags.isEmpty && talent.selfEvaluation.trim().isNotEmpty) {
      tags.add('有自我评价');
    }
    return tags;
  }

  static String _buildUpdatedText(String updatedAt) {
    final DateTime? parsed = DateTime.tryParse(updatedAt);
    if (parsed == null) {
      return updatedAt.isEmpty ? '更新时间未知' : updatedAt;
    }
    final String month = parsed.month.toString().padLeft(2, '0');
    final String day = parsed.day.toString().padLeft(2, '0');
    return '$month-$day 更新';
  }
}

class _CandidateAvatar extends StatelessWidget {
  const _CandidateAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.asset(
        'assets/images/mou52cw6-js17mxu.png',
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
    if (avatarUrl.isEmpty) {
      return fallback;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        avatarUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _TalentsEmptyState extends StatelessWidget {
  const _TalentsEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 48),
      child: Center(
        child: Text(
          '暂无人才数据',
          style: TextStyle(
            color: Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TalentLoadError extends StatelessWidget {
  const _TalentLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              '人才列表加载失败',
              style: TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
