import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';

class OrderReviewPage extends StatefulWidget {
  const OrderReviewPage({super.key});

  @override
  State<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends State<OrderReviewPage> {
  final TextEditingController _commentController = TextEditingController();

  double _rating = 1.5;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  bool get _canPublish => _commentController.text.trim().isNotEmpty;

  String get _ratingLabel {
    if (_rating <= 1.5) return '很差';
    if (_rating <= 2.5) return '一般';
    if (_rating <= 3.5) return '满意';
    if (_rating <= 4.5) return '不错';
    return '很棒';
  }

  void _showPlaceholder(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              _showPlaceholder('暂无可返回页面');
            }
          },
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          '评价',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: <Widget>[
            const _ReviewOrderCard(),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '综合评价',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RatingRow(
                    rating: _rating,
                    ratingLabel: _ratingLabel,
                    onRatingChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 264,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            maxLength: 500,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            decoration: const InputDecoration(
                              hintText: '写评论...',
                              hintStyle: TextStyle(
                                color: Color(0xFF8C8C8C),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              counterText: '',
                              isCollapsed: true,
                            ),
                            style: const TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${_commentController.text.characters.length}/500',
                            style: const TextStyle(
                              color: Color(0xFFBFBFBF),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 16 / 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showPlaceholder('上传图片（占位）'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 106,
                      height: 106,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.photo_camera_outlined,
                            size: 24,
                            color: Color(0xFF595959),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '上传图片',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF595959),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5),
              ),
            ),
            child: Opacity(
              opacity: _canPublish ? 1 : 0.3,
              child: IgnorePointer(
                ignoring: !_canPublish,
                child: PrimaryButton(
                  label: '发布',
                  onPressed: () => _showPlaceholder('发布评价（占位）'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewOrderCard extends StatelessWidget {
  const _ReviewOrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 11, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const <Widget>[
          _ReviewTitleRow(title: '法签通个人服务', price: '¥9,000.00'),
          SizedBox(height: 12),
          _ReviewInfoRow(label: '服务商', value: '中欧出海签证服务有限公司'),
          SizedBox(height: 4),
          _ReviewInfoRow(label: '套餐类型', value: '基础套餐'),
          SizedBox(height: 4),
          _ReviewInfoRow(label: '订单号', value: 'CLSKJ98793120238'),
        ],
      ),
    );
  }
}

class _ReviewTitleRow extends StatelessWidget {
  const _ReviewTitleRow({required this.title, required this.price});

  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 22 / 16,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          price,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF262626),
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 22 / 16,
          ),
        ),
      ],
    );
  }
}

class _ReviewInfoRow extends StatelessWidget {
  const _ReviewInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF8C8C8C),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 18 / 12,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({
    required this.rating,
    required this.ratingLabel,
    required this.onRatingChanged,
  });

  final double rating;
  final String ratingLabel;
  final ValueChanged<double> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: <Widget>[
          Text(
            '服务评价',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 16),
          ...List<Widget>.generate(5, (index) {
            final starNumber = index + 1.0;
            IconData icon;
            Color color;

            if (rating >= starNumber) {
              icon = Icons.star_rounded;
              color = const Color(0xFFFFC53D);
            } else if (rating >= starNumber - 0.5) {
              icon = Icons.star_half_rounded;
              color = const Color(0xFFFFC53D);
            } else {
              icon = Icons.star_border_rounded;
              color = const Color(0xFFD9D9D9);
            }

            return Padding(
              padding: EdgeInsets.only(right: index == 4 ? 0 : 16),
              child: GestureDetector(
                onTap: () => onRatingChanged(index + 1.0),
                child: Icon(icon, size: 24, color: color),
              ),
            );
          }),
          const Spacer(),
          Text(
            ratingLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
