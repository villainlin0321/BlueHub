import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_exception.dart';
import '../../../../shared/network/page_result.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/visa_service_card.dart';
import '../../application/search_page/visa_provider_search_state.dart';
import '../../data/provider_models.dart';

class VisaProviderSearchPageView extends StatelessWidget {
  const VisaProviderSearchPageView({
    super.key,
    required this.state,
    required this.providersAsync,
    required this.collectedPackageIdsAsync,
    required this.onHistoryTap,
    required this.onResultTap,
    required this.onRetrySearch,
    required this.onClearHistory,
  });

  final VisaProviderSearchState state;
  final AsyncValue<PageResult<VisaProviderListVO>>? providersAsync;
  final AsyncValue<Set<int>>? collectedPackageIdsAsync;
  final ValueChanged<String> onHistoryTap;
  final void Function(VisaProviderListVO item, bool isCollected) onResultTap;
  final VoidCallback onRetrySearch;
  final VoidCallback onClearHistory;

  @override
  Widget build(BuildContext context) {
    if (state.isShowingResults && providersAsync != null) {
      return ColoredBox(
        color: const Color(0xFFF5F7FA),
        child: _SearchResultSection(
          providersAsync: providersAsync!,
          collectedPackageIdsAsync: collectedPackageIdsAsync,
          onRetry: onRetrySearch,
          onTap: onResultTap,
        ),
      );
    }

    return _HistorySection(
      historyKeywords: state.historyKeywords,
      isLoading: state.isLoadingHistory,
      isClearing: state.isClearingHistory,
      onTap: onHistoryTap,
      onClear: onClearHistory,
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({
    required this.historyKeywords,
    required this.isLoading,
    required this.isClearing,
    required this.onTap,
    required this.onClear,
  });

  static const double _chipHorizontalPadding = 24;
  static const double _chipSpacing = 12;
  static const TextStyle _chipTextStyle = TextStyle(
    color: Color(0xFF262626),
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  final List<String> historyKeywords;
  final bool isLoading;
  final bool isClearing;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '签证搜索.历史记录'.tr(),
                  style: TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: historyKeywords.isEmpty || isClearing
                      ? null
                      : onClear,
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                  icon: isClearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Opacity(
                          opacity: historyKeywords.isEmpty ? 0.35 : 1,
                          child: const AppSvgIcon(
                            assetPath:
                                'assets/images/visa_search_history_clear.svg',
                            fallback: Icons.delete_outline_rounded,
                            size: 16,
                            color: Color(0x99191F25),
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (historyKeywords.isEmpty)
            Text(
              '签证搜索.暂无搜索记录'.tr(),
              style: TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            )
          else
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final List<String> visibleKeywords = _visibleKeywords(
                  context: context,
                  keywords: historyKeywords,
                  maxWidth: constraints.maxWidth,
                );
                return Wrap(
                  spacing: _chipSpacing,
                  runSpacing: 14,
                  children: visibleKeywords
                      .map(
                        (String keyword) => _HistoryChip(
                          label: keyword,
                          onTap: () => onTap(keyword),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
        ],
      ),
    );
  }

  List<String> _visibleKeywords({
    required BuildContext context,
    required List<String> keywords,
    required double maxWidth,
  }) {
    final List<String> visible = <String>[];
    final TextPainter painter = TextPainter(
      textDirection: Directionality.of(context),
      maxLines: 1,
    );

    double currentRowWidth = 0;
    int currentRow = 1;
    for (final String keyword in keywords) {
      painter.text = TextSpan(text: keyword, style: _chipTextStyle);
      painter.layout();
      final double chipWidth = painter.width + _chipHorizontalPadding;
      final double nextWidth = currentRowWidth == 0
          ? chipWidth
          : currentRowWidth + _chipSpacing + chipWidth;

      if (nextWidth > maxWidth) {
        currentRow += 1;
        if (currentRow > 3) {
          break;
        }
        currentRowWidth = chipWidth;
      } else {
        currentRowWidth = nextWidth;
      }
      visible.add(keyword);
    }

    return visible;
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(label, style: _HistorySection._chipTextStyle),
        ),
      ),
    );
  }
}

class _SearchResultSection extends StatelessWidget {
  const _SearchResultSection({
    required this.providersAsync,
    required this.collectedPackageIdsAsync,
    required this.onRetry,
    required this.onTap,
  });

  final AsyncValue<PageResult<VisaProviderListVO>> providersAsync;
  final AsyncValue<Set<int>>? collectedPackageIdsAsync;
  final VoidCallback onRetry;
  final void Function(VisaProviderListVO item, bool isCollected) onTap;

  @override
  Widget build(BuildContext context) {
    return providersAsync.when(
      data: (PageResult<VisaProviderListVO> pageResult) {
        if (pageResult.list.isEmpty) {
          return Center(
            child: AppEmptyState(message: '签证搜索.未找到相关签证服务商'.tr()),
          );
        }

        final Set<int>? collectedPackageIds =
            collectedPackageIdsAsync?.asData?.value;
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: pageResult.list.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (BuildContext context, int index) {
            final VisaProviderListVO item = pageResult.list[index];
            final bool isCollected =
                collectedPackageIds?.contains(item.latestPackage.packageId) ??
                false;
            return VisaServiceCard(
              data: _buildCardData(item),
              onTap: () => onTap(item, isCollected),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stackTrace) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  _resolveVisaProviderErrorMessage(error),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
              ],
            ),
          ),
        );
      },
    );
  }

  VisaServiceCardData _buildCardData(VisaProviderListVO item) {
    return VisaServiceCardData(
      title: item.name.trim().isEmpty ? '首页.签证服务商'.tr() : item.name,
      avatarUrl: item.logoUrl.trim().isEmpty ? null : item.logoUrl.trim(),
      rating: item.rating.toStringAsFixed(1),
      cases: item.caseCount > 0
          ? '首页.服务案例数'.tr(
              namedArgs: <String, String>{'count': item.caseCount.toString()},
            )
          : '首页.暂无服务案例'.tr(),
      tags: item.tags.isEmpty ? <String>['首页.签证服务'.tr()] : item.tags,
      description: item.brief.trim().isEmpty ? '首页.暂无服务商简介'.tr() : item.brief.trim(),
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: item.latestPackage.name.trim().isEmpty
              ? '首页.推荐套餐'.tr()
              : item.latestPackage.name,
          price: _formatVisaListPrice(item.latestPackage.priceFrom),
        ),
      ],
      verified: item.isVerified,
    );
  }

  String _formatVisaListPrice(double price) {
    final String value = price % 1 == 0
        ? price.toInt().toString()
        : price.toStringAsFixed(1);
    return '¥$value';
  }

  String _resolveVisaProviderErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '首页.签证服务加载失败'.tr();
  }
}
