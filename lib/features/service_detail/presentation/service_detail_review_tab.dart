import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/app_empty_state.dart';
import '../../visa/data/provider_models.dart';

import 'package:europepass/shared/ui/test_style.dart';
class ServiceDetailReviewTab extends StatefulWidget {
  const ServiceDetailReviewTab({
    super.key,
    required this.review,
    this.isLoading = false,
    this.errorMessage,
  });

  final ReviewVO? review;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<ServiceDetailReviewTab> createState() => _ServiceDetailReviewTabState();
}

class _ServiceDetailReviewTabState extends State<ServiceDetailReviewTab> {
  final Set<int> _expandedReviewIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.review == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.errorMessage != null && widget.review == null) {
      return _ReviewPlaceholder(message: widget.errorMessage!);
    }

    final ReviewVO? review = widget.review;
    if (review == null || review.list.isEmpty) {
      return _ReviewPlaceholder(message: '服务详情.暂无评价数据'.tr());
    }

    return ListView.builder(
      key: const PageStorageKey<String>('service-detail-review-tab'),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
      itemCount: review.list.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ReviewSummaryCard(summary: review.summary),
          );
        }

        final reviewIndex = index - 1;
        final ReviewItemVO item = review.list[reviewIndex];
        return _ReviewCard(
          review: item,
          isExpanded: _expandedReviewIndexes.contains(reviewIndex),
          onExpand: () {
            setState(() {
              _expandedReviewIndexes.add(reviewIndex);
            });
          },
        );
      },
    );
  }
}

class _ReviewSummaryCard extends StatelessWidget {
  const _ReviewSummaryCard({required this.summary});

  final SummaryVO summary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: Row(
        children: <Widget>[
          _ReviewSummaryScore(summary: summary),
          const Spacer(),
          const _ReviewSortSwitch(),
        ],
      ),
    );
  }
}

class _ReviewSummaryScore extends StatelessWidget {
  const _ReviewSummaryScore({required this.summary});

  final SummaryVO summary;

  @override
  Widget build(BuildContext context) {
    final scoreTextStyle = TestStyle.regular(fontSize: 34, color: const Color(0xFFFE5815));
    final labelTextStyle = TestStyle.regular(fontSize: 12, color: const Color(0xFFFE5815));

    return SizedBox(
      width: 128,
      height: 37,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: Text(
              summary.averageRating.toStringAsFixed(1),
              style: scoreTextStyle,
            ),
          ),
          Positioned(
            left: 62,
            top: 6,
            child: Text(
              summary.label.isEmpty ? '服务详情.暂无标签'.tr() : summary.label,
              style: labelTextStyle,
            ),
          ),
          const Positioned(left: 60, top: 25, child: _ReviewSummaryStarRow()),
        ],
      ),
    );
  }
}

class _ReviewSummaryStarRow extends StatelessWidget {
  const _ReviewSummaryStarRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 2),
          child: const Icon(
            Icons.star_rounded,
            color: Color(0xFFFE5815),
            size: 12,
          ),
        );
      }),
    );
  }
}

class _ReviewSortSwitch extends StatelessWidget {
  const _ReviewSortSwitch();

  @override
  Widget build(BuildContext context) {
    final selectedTextStyle = TestStyle.medium(fontSize: 14, color: const Color(0xFF262626));
    final normalTextStyle = TestStyle.regular(fontSize: 14, color: const Color(0xFF8C8C8C));

    return SizedBox(
      width: 90,
      height: 32,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 1,
            top: 1,
            child: Container(
              width: 44,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            left: 9,
            top: 6,
            child: Text('服务详情.最热'.tr(), style: selectedTextStyle),
          ),
          Positioned(
            left: 53,
            top: 6,
            child: Text('服务详情.最新'.tr(), style: normalTextStyle),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.isExpanded,
    required this.onExpand,
  });

  final ReviewItemVO review;
  final bool isExpanded;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ReviewHeader(review: review),
          const SizedBox(height: 14),
          _ExpandableReviewText(
            content: review.content,
            isExpanded: isExpanded,
            onExpand: onExpand,
          ),
          if (isExpanded && review.images.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _ReviewPhotoRow(photoAssetPaths: review.images),
          ],
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.review});

  final ReviewItemVO review;

  @override
  Widget build(BuildContext context) {
    final nameStyle = TestStyle.medium(fontSize: 14, color: const Color(0xFF262626));
    final timeStyle = TestStyle.regular(fontSize: 14, color: const Color(0xFF8C8C8C));

    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ReviewAvatar(initials: _resolveReviewInitial(review)),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 34,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: 20,
                    child: Row(
                      children: <Widget>[
                        Text(_resolveReviewUserName(review), style: nameStyle),
                        const Spacer(),
                        Text(
                          _formatReviewDate(review.createdAt),
                          style: timeStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  _ReviewRatingStarRow(rating: review.rating),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewAvatar extends StatelessWidget {
  const _ReviewAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[Color(0xFFE5F3FF), Color(0xFFC4E2FE)],
          stops: <double>[0.5, 1],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TestStyle.numberBold(fontSize: 11, color: const Color(0xFF096DD9)),
      ),
    );
  }
}

class _ReviewRatingStarRow extends StatelessWidget {
  const _ReviewRatingStarRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(5, (index) {
        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 2),
          child: Icon(
            Icons.star_rounded,
            color: index < rating
                ? const Color(0xFFFE5815)
                : const Color(0xFFE5E5E5),
            size: 12,
          ),
        );
      }),
    );
  }
}

class _ExpandableReviewText extends StatelessWidget {
  const _ExpandableReviewText({
    required this.content,
    required this.isExpanded,
    required this.onExpand,
  });

  final String content;
  final bool isExpanded;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final textStyle = TestStyle.regular(fontSize: 15, color: const Color(0xFF262626));
    final expandStyle = TestStyle.regular(fontSize: 15, color: const Color(0xFF096DD9));

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: content, style: textStyle),
          textDirection: Directionality.of(context),
          maxLines: 3,
        )..layout(maxWidth: constraints.maxWidth);

        final exceeded = textPainter.didExceedMaxLines;
        if (isExpanded || !exceeded) {
          return Text(content, style: textStyle);
        }

        return Stack(
          children: <Widget>[
            Text(
              content,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onExpand,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.only(left: 8),
                  child: Text('服务详情.展开'.tr(), style: expandStyle),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReviewPhotoRow extends StatelessWidget {
  const _ReviewPhotoRow({required this.photoAssetPaths});

  final List<String> photoAssetPaths;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List<Widget>.generate(photoAssetPaths.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            right: index == photoAssetPaths.length - 1 ? 0 : 12,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: photoAssetPaths[index],
              width: 106,
              height: 106,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) {
                return Container(
                  width: 106,
                  height: 106,
                  color: const Color(0xFFF5F5F5),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: Color(0xFFBFBFBF),
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _ReviewPlaceholder extends StatelessWidget {
  const _ReviewPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    if (message == '服务详情.暂无评价数据'.tr()) {
      return Center(
        child: AppEmptyState(
          message: '服务详情.暂无评价数据'.tr(),
          padding: const EdgeInsets.all(24),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8C8C8C)),
        ),
      ),
    );
  }
}

/// 统一提取评价用户名，优先昵称，其次手机号和邮箱。
String _resolveReviewUserName(ReviewItemVO review) {
  final String nickname = review.user.nickname.trim();
  if (nickname.isNotEmpty) {
    return nickname;
  }
  return '服务详情.匿名用户'.tr();
}

/// 提取评价头像占位字，优先取昵称首字，否则展示占位符。
String _resolveReviewInitial(ReviewItemVO review) {
  final String userName = _resolveReviewUserName(review);
  return userName.isEmpty ? '?' : userName.characters.first;
}

/// 格式化评价时间，接口异常时回退原始字符串。
String _formatReviewDate(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw;
  }
  final String month = parsed.month.toString().padLeft(2, '0');
  final String day = parsed.day.toString().padLeft(2, '0');
  return '${parsed.year}.$month.$day';
}
