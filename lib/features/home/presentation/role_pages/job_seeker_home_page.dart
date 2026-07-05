import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_toast.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/models/app_currency.dart';
import '../../../../shared/network/api_exception.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_user_avatar.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/job_position_card.dart';
import '../../../../shared/widgets/job_seeker_page_background.dart';
import '../../../../shared/widgets/message_center_icon_button.dart';
import '../../../../shared/ui/test_keys.dart';
import '../../../auth/application/auth_session_provider.dart';
import '../../../auth/application/auth_user.dart';
import '../../../jobs/data/job_models.dart';
import '../../../jobs/presentation/job_apply_helper.dart';
import '../../../jobs/presentation/job_detail_page.dart';
import '../../../me/presentation/current_user_view_data.dart';
import '../../../service_detail/presentation/service_detail_page.dart';
import '../../data/home_models.dart';
import '../../data/home_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';
/// 求职者首页：独立页面文件，后续该角色的业务逻辑统一放在这里处理。
class JobSeekerHomePage extends ConsumerWidget {
  const JobSeekerHomePage({super.key});

  static const List<_ShortcutItem> _shortcutItems = <_ShortcutItem>[
    _ShortcutItem(
      labelKey: '首页.AI招聘',
      assetPath: 'assets/images/mon5bjog-oey0vv1.svg',
      colors: <Color>[Color(0xFF52A9FF), Color(0xFF0887FF)],
      fallback: Icons.auto_awesome_rounded,
      destination: _ShortcutDestination.aiAssistant,
    ),
    _ShortcutItem(
      labelKey: '首页.欧洲岗',
      assetPath: 'assets/images/mon5bjog-wp0nhm8.svg',
      colors: <Color>[Color(0xFFFF943C), Color(0xFFFF5900)],
      fallback: Icons.work_outline_rounded,
      destination: _ShortcutDestination.jobs,
    ),
    _ShortcutItem(
      labelKey: '首页.签证',
      assetPath: 'assets/images/mon5bjog-8hp521f.svg',
      colors: <Color>[Color(0xFF01D99B), Color(0xFF00B879)],
      fallback: Icons.assignment_outlined,
      destination: _ShortcutDestination.visa,
    ),
    _ShortcutItem(
      labelKey: '首页.简历',
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

    return Column(
      key: AppTestKeys.pageJobSeekerHome,
      children: <Widget>[
        const _HomeTopHeader(),
        Expanded(
          child: ListView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.only(bottom: bottomPadding + 20),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 15, 0),
                child: _ShortcutRow(
                  items: JobSeekerHomePage._shortcutItems,
                  onItemTap: (_ShortcutItem item) =>
                      _handleShortcutTap(context, item),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go(RoutePaths.ai),
                    borderRadius: BorderRadius.circular(12),
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
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: _HomeSectionHeader(
                  title: '首页.热门签证套餐'.tr(),
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
                  title: '首页.最新欧洲岗位'.tr(),
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
          ),
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
  const _HomeTopHeader();

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

String _homeGreetingKeyForHour(int hour) {
  if (hour < 11) {
    return '首页.早上好';
  }
  if (hour < 14) {
    return '首页.中午好';
  }
  if (hour < 18) {
    return '首页.下午好';
  }
  return '首页.晚上好';
}

class _HeaderProfileRow extends ConsumerWidget {
  const _HeaderProfileRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AuthUser? currentUser = ref.watch(authSessionProvider).user;
    final CurrentUserViewData userViewData = CurrentUserViewData.fromAuthUser(
      currentUser,
    );
    final String greetingKey = _homeGreetingKeyForHour(DateTime.now().hour);

    return Row(
      children: <Widget>[
        GestureDetector(
          onTap: () => context.push(RoutePaths.myInfo),
          behavior: HitTestBehavior.opaque,
          child: AppUserAvatar(
            imageUrl: userViewData.avatarUrl,
            size: 32,
            placeholderAssetPath: 'assets/images/mon5bjog-wv3qvoa.png',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greetingKey.tr(
                  namedArgs: <String, String>{'name': userViewData.nickname},
                ),
                style: TestStyle.medium(fontSize: 15, color: const Color(0xFF262626)),
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
                    '国家.德国'.tr(),
                    style: TestStyle.pingFangRegular(fontSize: 12, color: const Color(0xFF595959)),
                  ),
                ],
              ),
            ],
          ),
        ),
        MessageCenterIconButton(color: Colors.black),
      ],
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(RoutePaths.visaProviderSearch),
        borderRadius: BorderRadius.circular(8),
        child: Container(
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
                  '首页.搜索签证服务欧洲岗位'.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TestStyle.pingFangRegular(fontSize: 14, color: const Color(0xFFBFBFBF)),
                ),
              ),
            ],
          ),
        ),
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
                item.labelKey.tr(),
                textAlign: TextAlign.center,
                style: TestStyle.regular(fontSize: 12, color: const Color(0xFF171A1D)),
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
    required this.labelKey,
    required this.assetPath,
    required this.colors,
    required this.fallback,
    required this.destination,
  });

  final String labelKey;
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
                  style: TestStyle.pingFangMedium(fontSize: 16, color: const Color(0xFF262626)),
                ),
              ),
              Text(
                '首页.更多'.tr(),
                style: TestStyle.pingFangRegular(fontSize: 14, color: const Color(0xFF8C8C8C)),
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _HomeSectionEmptyState(message: '首页.暂无热门签证套餐'.tr()),
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
              fallback: '首页.热门签证套餐加载失败'.tr(),
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

  /// 处理首页岗位投递，并透传统一的成功/失败提示文案。
  Future<void> _handleApply(BuildContext context, JobListVO job) async {
    final String? errorMessage = await submitJobApplication(
      context,
      jobId: job.jobId,
    );
    if (!context.mounted) {
      return;
    }
    AppToast.show(errorMessage ?? '首页.投递成功'.tr());
  }

  /// 根据接口状态切换最新岗位区块的加载、错误、空态和正常列表。
  @override
  Widget build(BuildContext context) {
    return jobsAsync.when(
      data: (List<JobListVO> jobs) {
        if (jobs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _HomeSectionEmptyState(message: '首页.暂无最新欧洲岗位'.tr()),
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
                  onApply: () => _handleApply(context, jobs[index]),
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
              fallback: '首页.最新欧洲岗位加载失败'.tr(),
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
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: AppEmptyState(
          message: message,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: TestStyle.regular(fontSize: 14, color: const Color(0xFF8C8C8C)),
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
            style: TestStyle.pingFangRegular(fontSize: 14, color: const Color(0xFF8C8C8C)),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.topRight,
                    child: RichText(
                      text: TextSpan(
                        style: TestStyle.medium(color: Color(0xFFFE5815)),
                        children: <InlineSpan>[
                          TextSpan(
                            text: data.pricePrefix,
                            style: TestStyle.regular(fontSize: 14),
                          ),
                          TextSpan(
                            text: data.priceValue,
                            style: TestStyle.regular(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    data.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.medium(fontSize: 16, color: const Color(0xFF262626)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
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
                        style: TestStyle.medium(fontSize: 12, color: const Color(0xFFFE5815)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        data.casesText,
                        style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
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
                        style: TestStyle.regular(fontSize: 12, color: Colors.white),
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
      title: packageName.trim().isEmpty ? '首页.签证套餐'.tr() : packageName.trim(),
      subtitle: _buildVisaSubtitle(),
      pricePrefix: priceDisplay.prefix,
      priceValue: priceDisplay.value,
      rating: _formatRating(),
      casesText: caseCount > 0
          ? '首页.案例数'.tr(
              namedArgs: <String, String>{'count': caseCount.toString()},
            )
          : '首页.暂无案例'.tr(),
      country: _formatCountryName(),
      ribbonAssetPath: _resolveRibbonAssetPath(),
      actionAssetPath: 'assets/images/mon5bjog-9ler7sj.png',
    );
  }

  /// 组装签证卡片的副标题，优先展示服务描述并补充预计时长。
  String _buildVisaSubtitle() {
    final String descriptionText = description.trim();
    if (descriptionText.isNotEmpty && estimatedDays > 0) {
      return '首页.约天数'.tr(
        namedArgs: <String, String>{
          'description': descriptionText,
          'days': estimatedDays.toString(),
        },
      );
    }
    if (descriptionText.isNotEmpty) {
      return descriptionText;
    }
    if (estimatedDays > 0) {
      return '首页.预计天数完成办理'.tr(
        namedArgs: <String, String>{'days': estimatedDays.toString()},
      );
    }
    final String providerText = providerName.trim();
    return providerText.isEmpty ? '首页.专业服务商提供办理支持'.tr() : providerText;
  }

  /// 格式化签证套餐价格，兼容常见币种符号与整数价格展示。
  ({String prefix, String value}) _buildPriceDisplay() {
    final ({String symbol, String value}) priceParts =
        AppCurrency.buildAmountParts(priceFrom, currency);
    return (prefix: priceParts.symbol, value: priceParts.value);
  }

  /// 格式化评分，确保 UI 始终展示单个小数位。
  String _formatRating() {
    final double normalized = rating <= 0 ? 0 : rating;
    return normalized.toStringAsFixed(1);
  }

  /// 把 ISO 国家码转换为首页角标展示文案。
  String _formatCountryName() {
    return switch (targetCountry.trim().toUpperCase()) {
      'DE' => '国家.德国'.tr(),
      'FR' => '国家.法国'.tr(),
      'IT' => '国家.意大利'.tr(),
      'ES' => '国家.西班牙'.tr(),
      'NL' => '国家.荷兰'.tr(),
      'BE' => '国家.比利时'.tr(),
      'AT' => '国家.奥地利'.tr(),
      'CH' => '国家.瑞士'.tr(),
      'PT' => '国家.葡萄牙'.tr(),
      'SE' => '国家.瑞典'.tr(),
      'NO' => '国家.挪威'.tr(),
      'DK' => '国家.丹麦'.tr(),
      'FI' => '国家.芬兰'.tr(),
      'IE' => '国家.爱尔兰'.tr(),
      'PL' => '国家.波兰'.tr(),
      _ =>
        targetCountry.trim().isEmpty
            ? '国家.签证'.tr()
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
    final String urgentLabel = '招聘卡片.急招'.tr();
    final String visaSupportLabel = '招聘卡片.提供签证'.tr();
    final List<String> tagLabels = tags
        .map((TagVO tag) => tag.label.trim())
        .where((String label) => label.isNotEmpty)
        .toList(growable: false);
    final List<String> requirementTags = <String>[
      ...tagLabels.where((String label) => label != urgentLabel),
      if (hasVisaSupport && !tagLabels.contains(visaSupportLabel))
        visaSupportLabel,
    ].take(3).toList(growable: false);
    final List<String> highlightTags = <String>[if (isUrgent) urgentLabel];

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
    return AppCurrency.formatRange(
      min: salaryMin,
      max: salaryMax,
      rawCurrency: salaryCurrency,
      period: salaryPeriod,
    );
  }

  /// 组装首页岗位卡片的地点文案。
  String _formatHomeLocation() {
    final List<String> parts = <String>[
      country.trim(),
      city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.join('·');
  }

}
