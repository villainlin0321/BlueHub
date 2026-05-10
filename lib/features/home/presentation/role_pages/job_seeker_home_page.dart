import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/job_position_card.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../jobs/data/job_models.dart';
import '../../../jobs/presentation/job_detail_page.dart';
import '../../../service_detail/presentation/service_detail_page.dart';
import '../../data/home_models.dart';
import '../../data/home_providers.dart';

/// 求职者首页：独立页面文件，后续该角色的业务逻辑统一放在这里处理。
class JobSeekerHomePage extends ConsumerWidget {
  const JobSeekerHomePage({super.key});

  static const List<_ShortcutItem> _shortcutItems = <_ShortcutItem>[
    _ShortcutItem(
      label: 'AI招聘',
      assetPath: 'assets/images/mon5bjog-oey0vv1.svg',
      colors: <Color>[Color(0xFF52A9FF), Color(0xFF0887FF)],
      fallback: Icons.auto_awesome_rounded,
      destination: _ShortcutDestination.aiAssistant,
    ),
    _ShortcutItem(
      label: '欧洲招聘',
      assetPath: 'assets/images/mon5bjog-wp0nhm8.svg',
      colors: <Color>[Color(0xFFFF943C), Color(0xFFFF5900)],
      fallback: Icons.work_outline_rounded,
      destination: _ShortcutDestination.jobs,
    ),
    _ShortcutItem(
      label: '签证服务',
      assetPath: 'assets/images/mon5bjog-8hp521f.svg',
      colors: <Color>[Color(0xFF01D99B), Color(0xFF00B879)],
      fallback: Icons.assignment_outlined,
      destination: _ShortcutDestination.visa,
    ),
    _ShortcutItem(
      label: '我的简历',
      assetPath: 'assets/images/mon5bjog-wivq7ef.svg',
      colors: <Color>[Color(0xFF52A9FF), Color(0xFF0887FF)],
      fallback: Icons.badge_outlined,
      destination: _ShortcutDestination.resumeList,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<List<HomeHotPackageVO>> hotVisaPackagesAsync = ref.watch(
      homeHotVisaPackagesProvider,
    );
    final AsyncValue<List<JobListVO>> latestJobsAsync = ref.watch(
      homeLatestJobsProvider,
    );

    return ListView(
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: bottomPadding + 20),
      children: <Widget>[
        _HomeTopHeader(
          onShortcutTap: (_ShortcutItem item) =>
              _handleShortcutTap(context, item),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/mon5bjog-qq5tufd.png',
              height: 80,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _HomeSectionHeader(
            title: '热门签证套餐',
            onTap: () => _handleVisaMoreTap(context),
          ),
        ),
        const SizedBox(height: 12),
        _HomeVisaPackagesSection(
          packagesAsync: hotVisaPackagesAsync,
          onRetry: () {
            ref.invalidate(homeHotVisaPackagesProvider);
          },
        ),
        const SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _HomeSectionHeader(
            title: '最新欧洲岗位',
            onTap: () => _handleJobsMoreTap(context),
          ),
        ),
        const SizedBox(height: 12),
        _HomeLatestJobsSection(
          jobsAsync: latestJobsAsync,
          onRetry: () {
            ref.invalidate(homeLatestJobsProvider);
          },
        ),
      ],
    );
  }

  /// 处理顶部快捷入口点击，根据入口类型跳转到对应页面或 Tab。
  void _handleShortcutTap(BuildContext context, _ShortcutItem item) {
    switch (item.destination) {
      case _ShortcutDestination.aiAssistant:
        // 跳转到底部 Tab 的 AI 助手页。
        context.go(RoutePaths.ai);
      case _ShortcutDestination.jobs:
        // 跳转到底部 Tab 的招聘页。
        context.go(RoutePaths.jobs);
      case _ShortcutDestination.visa:
        // 跳转到底部 Tab 的签证页。
        context.go(RoutePaths.visa);
      case _ShortcutDestination.resumeList:
        // 简历入口进入独立的简历列表页。
        context.push(RoutePaths.myResume);
    }
  }

  /// 处理热门签证套餐区块“更多”点击，进入签证主列表页。
  void _handleVisaMoreTap(BuildContext context) {
    context.go(RoutePaths.visa);
  }

  /// 处理最新欧洲岗位区块“更多”点击，进入招聘主列表页。
  void _handleJobsMoreTap(BuildContext context) {
    context.go(RoutePaths.jobs);
  }
}

class _HomeTopHeader extends StatelessWidget {
  const _HomeTopHeader({required this.onShortcutTap});

  final ValueChanged<_ShortcutItem> onShortcutTap;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return JobSeekerPageBackground(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, topPadding + 6, 15, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const _HeaderProfileRow(),
            const SizedBox(height: 12),
            const _HomeSearchBar(),
            const SizedBox(height: 20),
            _ShortcutRow(
              items: JobSeekerHomePage._shortcutItems,
              onItemTap: onShortcutTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.items, required this.onItemTap});

  final List<_ShortcutItem> items;
  final ValueChanged<_ShortcutItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map(
            (item) => _ShortcutButton(item: item, onTap: () => onItemTap(item)),
          )
          .toList(growable: false),
    );
  }
}

class _HeaderProfileRow extends StatelessWidget {
  const _HeaderProfileRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/mon5bjog-wv3qvoa.png',
            width: 32,
            height: 32,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '早上好，程先生',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  const AppSvgIcon(
                    assetPath: 'assets/images/mon5bjog-7bcl82r.svg',
                    fallback: Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF595959),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '德国',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF595959),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const _MessageButton(),
      ],
    );
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          const Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: AppSvgIcon(
                assetPath: 'assets/images/mon5bjog-vgesd2k.svg',
                fallback: Icons.chat_bubble_outline_rounded,
                size: 24,
                color: Color(0xFF171A1D),
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
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

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const AppSvgIcon(
            assetPath: 'assets/images/mon5bjog-j2j6s3e.svg',
            fallback: Icons.search_rounded,
            size: 16,
            color: Color(0xFFBFBFBF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '搜索签证服务/欧洲岗位',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFBFBFBF),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({required this.item, required this.onTap});

  final _ShortcutItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: item.colors,
                  ),
                ),
                child: Center(
                  child: AppSvgIcon(
                    assetPath: item.assetPath,
                    fallback: item.fallback,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF171A1D),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ShortcutDestination { aiAssistant, jobs, visa, resumeList }

class _ShortcutItem {
  const _ShortcutItem({
    required this.label,
    required this.assetPath,
    required this.colors,
    required this.fallback,
    required this.destination,
  });

  final String label;
  final String assetPath;
  final List<Color> colors;
  final IconData fallback;
  final _ShortcutDestination destination;
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, this.onTap});

  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                '更多',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8C8C8C),
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFFBFBFBF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeVisaPackagesSection extends StatelessWidget {
  const _HomeVisaPackagesSection({
    required this.packagesAsync,
    required this.onRetry,
  });

  final AsyncValue<List<HomeHotPackageVO>> packagesAsync;
  final VoidCallback onRetry;

  /// 根据接口状态切换签证套餐区块的加载、错误、空态和正常列表。
  @override
  Widget build(BuildContext context) {
    return packagesAsync.when(
      data: (List<HomeHotPackageVO> packages) {
        if (packages.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _HomeSectionEmptyState(message: '暂无热门签证套餐'),
          );
        }
        return SizedBox(
          height: 124,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            itemCount: packages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (BuildContext context, int index) {
              return _VisaMiniCard(
                data: packages[index].toVisaCardData(),
                onTap: () => context.push(
                  RoutePaths.serviceDetail,
                  extra: ServiceDetailPageArgs(
                    packageId: packages[index].packageId,
                    providerId: packages[index].providerId,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: _HomeVisaPackagesLoadingState(),
      ),
      error: (Object error, StackTrace stackTrace) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _HomeSectionErrorState(
            message: _resolveHomeSectionErrorMessage(
              error,
              fallback: '热门签证套餐加载失败，请稍后重试',
            ),
            onRetry: onRetry,
          ),
        );
      },
    );
  }
}

class _HomeLatestJobsSection extends StatelessWidget {
  const _HomeLatestJobsSection({
    required this.jobsAsync,
    required this.onRetry,
  });

  final AsyncValue<List<JobListVO>> jobsAsync;
  final VoidCallback onRetry;

  /// 根据接口状态切换最新岗位区块的加载、错误、空态和正常列表。
  @override
  Widget build(BuildContext context) {
    return jobsAsync.when(
      data: (List<JobListVO> jobs) {
        if (jobs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: _HomeSectionEmptyState(message: '暂无最新欧洲岗位'),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: List<Widget>.generate(jobs.length, (int index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == jobs.length - 1 ? 0 : 12,
                ),
                child: JobPositionCard(
                  data: jobs[index].toHomeJobCardData(),
                  onTap: () => context.push(
                    RoutePaths.jobDetail,
                    extra: JobDetailPageArgs(jobId: jobs[index].jobId),
                  ),
                  onApply: () {},
                ),
              );
            }),
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: _HomeLatestJobsLoadingState(),
      ),
      error: (Object error, StackTrace stackTrace) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _HomeSectionErrorState(
            message: _resolveHomeSectionErrorMessage(
              error,
              fallback: '最新欧洲岗位加载失败，请稍后重试',
            ),
            onRetry: onRetry,
          ),
        );
      },
    );
  }
}

class _HomeSectionEmptyState extends StatelessWidget {
  const _HomeSectionEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 124,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF8C8C8C),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _HomeSectionErrorState extends StatelessWidget {
  const _HomeSectionErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFBFBFBF),
            size: 28,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('重试')),
        ],
      ),
    );
  }
}

class _HomeVisaPackagesLoadingState extends StatelessWidget {
  const _HomeVisaPackagesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 124,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _HomeLatestJobsLoadingState extends StatelessWidget {
  const _HomeLatestJobsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _VisaMiniCardData {
  const _VisaMiniCardData({
    required this.title,
    required this.subtitle,
    required this.pricePrefix,
    required this.priceValue,
    required this.rating,
    required this.casesText,
    required this.country,
    required this.ribbonAssetPath,
    required this.actionAssetPath,
  });

  final String title;
  final String subtitle;
  final String pricePrefix;
  final String priceValue;
  final String rating;
  final String casesText;
  final String country;
  final String ribbonAssetPath;
  final String actionAssetPath;
}

class _VisaMiniCard extends StatelessWidget {
  const _VisaMiniCard({required this.data, this.onTap});

  final _VisaMiniCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = SizedBox(
      width: 240,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          color: Color(0xFFFE5815),
                          fontWeight: FontWeight.w500,
                        ),
                        children: <InlineSpan>[
                          TextSpan(
                            text: data.pricePrefix,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 24 / 14,
                            ),
                          ),
                          TextSpan(
                            text: data.priceValue,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 24 / 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF262626),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF8C8C8C),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFE5815),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        data.rating,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFFFE5815),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.casesText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8C8C8C),
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Image.asset(data.actionAssetPath, width: 20, height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: SizedBox(
              width: 63,
              height: 32,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  SvgPicture.asset(data.ribbonAssetPath, fit: BoxFit.cover),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        data.country,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }
}

/// 提取首页区块错误文案，优先复用接口层返回的业务提示。
String _resolveHomeSectionErrorMessage(
  Object error, {
  required String fallback,
}) {
  if (error is ApiException) {
    return error.message;
  }
  return fallback;
}

extension on HomeHotPackageVO {
  /// 将热门签证套餐接口模型映射为首页卡片展示数据。
  _VisaMiniCardData toVisaCardData() {
    final ({String prefix, String value}) priceDisplay = _buildPriceDisplay();
    return _VisaMiniCardData(
      title: packageName.trim().isEmpty ? '签证套餐' : packageName.trim(),
      subtitle: _buildVisaSubtitle(),
      pricePrefix: priceDisplay.prefix,
      priceValue: priceDisplay.value,
      rating: _formatRating(),
      casesText: caseCount > 0 ? '$caseCount案例' : '暂无案例',
      country: _formatCountryName(),
      ribbonAssetPath: _resolveRibbonAssetPath(),
      actionAssetPath: 'assets/images/mon5bjog-9ler7sj.png',
    );
  }

  /// 组装签证卡片的副标题，优先展示服务描述并补充预计时长。
  String _buildVisaSubtitle() {
    final String descriptionText = description.trim();
    if (descriptionText.isNotEmpty && estimatedDays > 0) {
      return '$descriptionText · 约$estimatedDays天';
    }
    if (descriptionText.isNotEmpty) {
      return descriptionText;
    }
    if (estimatedDays > 0) {
      return '预计$estimatedDays天完成办理';
    }
    final String providerText = providerName.trim();
    return providerText.isEmpty ? '专业服务商提供办理支持' : providerText;
  }

  /// 格式化签证套餐价格，兼容常见币种符号与整数价格展示。
  ({String prefix, String value}) _buildPriceDisplay() {
    final String symbol = _resolveCurrencyPrefix(currency);
    final String priceText = priceFrom % 1 == 0
        ? priceFrom.toInt().toString()
        : priceFrom.toStringAsFixed(1);
    return (prefix: symbol, value: priceText);
  }

  /// 格式化评分，确保 UI 始终展示单个小数位。
  String _formatRating() {
    final double normalized = rating <= 0 ? 0 : rating;
    return normalized.toStringAsFixed(1);
  }

  /// 把 ISO 国家码转换为首页角标展示文案。
  String _formatCountryName() {
    return switch (targetCountry.trim().toUpperCase()) {
      'DE' => '德国',
      'FR' => '法国',
      'IT' => '意大利',
      'ES' => '西班牙',
      'NL' => '荷兰',
      'BE' => '比利时',
      'AT' => '奥地利',
      'CH' => '瑞士',
      'PT' => '葡萄牙',
      'SE' => '瑞典',
      'NO' => '挪威',
      'DK' => '丹麦',
      'FI' => '芬兰',
      'IE' => '爱尔兰',
      'PL' => '波兰',
      _ =>
        targetCountry.trim().isEmpty
            ? '签证'
            : targetCountry.trim().toUpperCase(),
    };
  }

  /// 根据国家简单区分彩带样式，保持首页视觉层次。
  String _resolveRibbonAssetPath() {
    return targetCountry.trim().toUpperCase() == 'DE'
        ? 'assets/images/mon5bjog-lmu6456.svg'
        : 'assets/images/mon5bjog-xpp1qgm.svg';
  }
}

extension on JobListVO {
  /// 将首页最新岗位接口模型映射为职位卡片数据。
  JobPositionCardData toHomeJobCardData() {
    final List<String> tagLabels = tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != '急招'),
      if (hasVisaSupport && !tagLabels.contains('提供签证')) '提供签证',
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[if (isUrgent) '急招'];

    return JobPositionCardData(
      title: title,
      salary: _formatHomeSalary(),
      requirementTags: requirementTags,
      highlightTags: highlightTags,
      company: employer.name,
      location: _formatHomeLocation(),
      showApplyButton: true,
    );
  }

  /// 组装首页岗位卡片的薪资展示。
  String _formatHomeSalary() {
    final String currencyText = _resolveCurrencyPrefix(salaryCurrency);
    final String minText = _formatHomeNumber(salaryMin);
    final String maxText = _formatHomeNumber(salaryMax);
    final String rangeText = salaryMax > 0
        ? '$currencyText$minText~$maxText'
        : '$currencyText$minText';
    if (salaryPeriod.isEmpty) {
      return rangeText;
    }
    return '$rangeText/$salaryPeriod';
  }

  /// 组装首页岗位卡片的地点文案。
  String _formatHomeLocation() {
    final List<String> parts = <String>[
      country.trim(),
      city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join('·');
  }

  /// 格式化首页岗位中的薪资数字，尽量避免多余的小数位。
  String _formatHomeNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

/// 统一处理首页卡片中的币种前缀，优先转成常见符号展示。
String _resolveCurrencyPrefix(String rawCurrency) {
  return switch (rawCurrency.trim().toUpperCase()) {
    'CNY' || 'RMB' => '¥',
    'EUR' => '€',
    'USD' => '\$',
    _ => rawCurrency.trim().isEmpty ? '¥' : '${rawCurrency.trim()} ',
  };
}
