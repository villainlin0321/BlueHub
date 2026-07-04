import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../visa/data/review_models.dart';
import '../../visa/data/review_providers.dart';
import '../../files/data/file_models.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../shared/widgets/upload_image_grid.dart';

import 'package:europepass/shared/ui/test_style.dart';
class OrderReviewPageArgs {
  const OrderReviewPageArgs({
    required this.orderId,
    required this.providerId,
    required this.title,
    required this.price,
    required this.providerName,
    required this.packageType,
    required this.orderNo,
  });

  final int orderId;
  final int providerId;
  final String title;
  final String price;
  final String providerName;
  final String packageType;
  final String orderNo;
}

class OrderReviewPage extends ConsumerStatefulWidget {
  const OrderReviewPage({super.key, required this.args});

  final OrderReviewPageArgs args;

  @override
  ConsumerState<OrderReviewPage> createState() => _OrderReviewPageState();
}

class _OrderReviewPageState extends ConsumerState<OrderReviewPage> {
  final TextEditingController _commentController = TextEditingController();

  double _rating = 5;
  bool _isSubmitting = false;
  bool _isUploadingImages = false;
  List<String> _uploadedImageUrls = const <String>[];

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

  bool get _canPublish =>
      _commentController.text.trim().isNotEmpty && !_isUploadingImages;

  String get _ratingLabel {
    if (_rating <= 1.5) return '评价.很差'.tr();
    if (_rating <= 2.5) return '评价.一般'.tr();
    if (_rating <= 3.5) return '评价.满意'.tr();
    if (_rating <= 4.5) return '评价.不错'.tr();
    return '评价.很棒'.tr();
  }

  void _showPlaceholder(String message) {
    AppToast.show(message);
  }

  Future<void> _handlePublish() async {
    if (!_canPublish || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(reviewServiceProvider)
          .createReview(
            request: CreateReviewBO(
              orderId: widget.args.orderId,
              providerId: widget.args.providerId,
              rating: _rating.round().clamp(1, 5),
              content: _commentController.text.trim(),
              images: _uploadedImageUrls,
            ),
          );
      if (!mounted) {
        return;
      }
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showPlaceholder(_normalizeError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _normalizeError(Object error) {
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? '评价.评价发布失败'.tr() : message;
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
              _showPlaceholder('订单.暂无可返回页面'.tr());
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
          '评价.标题'.tr(),
          style: TestStyle.pingFangMedium(fontSize: 17, color: const Color(0xE6000000)),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          children: <Widget>[
            _ReviewOrderCard(args: widget.args),
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
                    '评价.综合评价'.tr(),
                    style: TestStyle.pingFangMedium(fontSize: 14, color: Colors.black),
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
                            decoration: InputDecoration(
                              hintText: '评价.写评论'.tr(),
                              hintStyle: TestStyle.pingFangRegular(fontSize: 13, color: Color(0xFF8C8C8C)),
                              border: InputBorder.none,
                              counterText: '',
                              isCollapsed: true,
                            ),
                            style: TestStyle.regular(fontSize: 13, color: Color(0xFF262626)),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            '${_commentController.text.characters.length}/500',
                            style: TestStyle.regular(fontSize: 12, color: Color(0xFFBFBFBF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: UploadImageGrid(
                      scene: FileScene.review,
                      onChanged: (List<String> imageUrls) {
                        _uploadedImageUrls = imageUrls;
                      },
                      onUploadingChanged: (bool isUploading) {
                        setState(() {
                          _isUploadingImages = isUploading;
                        });
                      },
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
              opacity: _canPublish && !_isSubmitting ? 1 : 0.3,
              child: IgnorePointer(
                ignoring: !_canPublish || _isSubmitting,
                child: PrimaryButton(
                  label: '评价.发布'.tr(),
                  onPressed: _handlePublish,
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
  const _ReviewOrderCard({required this.args});

  final OrderReviewPageArgs args;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 14, 11, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          _ReviewTitleRow(title: args.title, price: args.price),
          const SizedBox(height: 12),
          _ReviewInfoRow(label: '订单.服务商'.tr(), value: args.providerName),
          const SizedBox(height: 4),
          _ReviewInfoRow(label: '我的.套餐类型'.tr(), value: args.packageType),
          const SizedBox(height: 4),
          _ReviewInfoRow(label: '我的.订单号'.tr(), value: args.orderNo),
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
            style: TestStyle.semibold(fontSize: 16, color: const Color(0xFF262626)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          price,
          style: TestStyle.medium(fontSize: 16, color: const Color(0xFF262626)),
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
          style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TestStyle.regular(fontSize: 12, color: const Color(0xFF8C8C8C)),
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
            '评价.服务评价'.tr(),
            style: TestStyle.pingFangRegular(fontSize: 13, color: const Color(0xFF8C8C8C)),
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
            style: TestStyle.regular(fontSize: 13, color: const Color(0xFF8C8C8C)),
          ),
        ],
      ),
    );
  }
}
