import 'package:flutter/material.dart';

class ServiceDetailReviewTab extends StatefulWidget {
  const ServiceDetailReviewTab({super.key});

  @override
  State<ServiceDetailReviewTab> createState() => _ServiceDetailReviewTabState();
}

class _ServiceDetailReviewTabState extends State<ServiceDetailReviewTab> {
  static const _reviewPhotoAssets = <String>[
    'assets/images/service_detail_review_photo_1-56586a.png',
    'assets/images/service_detail_review_photo_2-56586a.png',
    'assets/images/service_detail_review_photo_3-56586a.png',
  ];

  static const _reviews = <_ReviewData>[
    _ReviewData(
      name: '王女士',
      time: '2026.04.18',
      content:
          '老板服务真的很靠谱，全程专业又省心。顾问熟悉各国政策，会根据个人情况定制方案，材料审核细致，避免遗漏出错。沟通及时高效，有疑问也会第一时间解释清楚，整体办理体验非常顺畅。',
      initials: '王',
      photoAssetPaths: _reviewPhotoAssets,
    ),
    _ReviewData(
      name: '陈先生',
      time: '2026.04.05',
      content:
          '老师会帮忙逐项核对德语材料，面签前还做了模拟辅导，沟通体验比较安心，适合第一次申请的人。整个进度节点也会提前提醒，不会让人手忙脚乱。',
      initials: '陈',
    ),
    _ReviewData(
      name: 'Lina',
      time: '2026.03.26',
      content: '套餐价格透明，没有额外隐形收费。提交节点和反馈时间都比较准，整体服务比较规范，适合希望流程清晰、预算明确的人。',
      initials: 'L',
    ),
  ];

  final Set<int> _expandedReviewIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey<String>('service-detail-review-tab'),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
      itemCount: _reviews.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _ReviewSummaryCard(),
          );
        }

        final reviewIndex = index - 1;
        final review = _reviews[reviewIndex];
        return _ReviewCard(
          review: review,
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
  const _ReviewSummaryCard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 37,
      child: Row(
        children: const <Widget>[
          _ReviewSummaryScore(),
          Spacer(),
          _ReviewSortSwitch(),
        ],
      ),
    );
  }
}

class _ReviewSummaryScore extends StatelessWidget {
  const _ReviewSummaryScore();

  @override
  Widget build(BuildContext context) {
    final scoreTextStyle = Theme.of(context).textTheme.displaySmall?.copyWith(
      color: const Color(0xFFFE5815),
      fontSize: 34,
      fontWeight: FontWeight.w400,
      height: 1.08,
    );
    final labelTextStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFFFE5815),
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.42,
    );

    return SizedBox(
      width: 128,
      height: 37,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: 0,
            child: Text('4.9', style: scoreTextStyle),
          ),
          Positioned(
            left: 62,
            top: 6,
            child: Text('超棒', style: labelTextStyle),
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
    final selectedTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF262626),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
    );
    final normalTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF8C8C8C),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.43,
    );

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
            child: Text('最热', style: selectedTextStyle),
          ),
          Positioned(
            left: 53,
            top: 6,
            child: Text('最新', style: normalTextStyle),
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

  final _ReviewData review;
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
          if (isExpanded && review.photoAssetPaths.isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            _ReviewPhotoRow(photoAssetPaths: review.photoAssetPaths),
          ],
        ],
      ),
    );
  }
}

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.review});

  final _ReviewData review;

  @override
  Widget build(BuildContext context) {
    final nameStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF262626),
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.43,
    );
    final timeStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF8C8C8C),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.21,
    );

    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _ReviewAvatar(initials: review.initials),
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
                        Text(review.name, style: nameStyle),
                        const Spacer(),
                        Text(review.time, style: timeStyle),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  const _ReviewRatingStarRow(),
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
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF096DD9),
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ReviewRatingStarRow extends StatelessWidget {
  const _ReviewRatingStarRow();

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
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF262626),
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.6,
    );
    final expandStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: const Color(0xFF096DD9),
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.6,
    );

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
                  child: Text('展开', style: expandStyle),
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
            child: Image.asset(
              photoAssetPaths[index],
              width: 106,
              height: 106,
              fit: BoxFit.cover,
            ),
          ),
        );
      }),
    );
  }
}

class _ReviewData {
  const _ReviewData({
    required this.name,
    required this.time,
    required this.content,
    required this.initials,
    this.photoAssetPaths = const <String>[],
  });

  final String name;
  final String time;
  final String content;
  final String initials;
  final List<String> photoAssetPaths;
}
