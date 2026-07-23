import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/network/api_error_feedback.dart';

import '../../visa/data/review_models.dart';
import '../../visa/data/review_providers.dart';
import '../../files/data/file_models.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
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
  List<UploadedImageValue> _uploadedImages = const <UploadedImageValue>[];

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

  /// 统一弹出页面内的轻提示，便于后续替换提示组件。
  void _showPlaceholder(String message) {
    AppToast.show(message);
  }

  /// 提交评价内容，并在成功后返回上一页通知刷新。
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
              imageFileIds: _uploadedImages
                  .map((UploadedImageValue item) => item.fileId)
                  .toList(growable: false),
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

  /// 规范化接口异常文案，避免直接向用户暴露冗余前缀。
  String _normalizeError(Object error) {
    return ApiErrorFeedback.resolveMessage(error, fallback: '评价.评价发布失败'.tr());
  }

  /// 构建评价主体区域，按设计稿控制留白、评分行与输入区比例。
  Widget _buildReviewPanel() {
    return Container(
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
            style: TestStyle.pingFangMedium(
              fontSize: 14,
              color: const Color(0xFF000000),
            ),
          ),
          const SizedBox(height: 12),
          _RatingRow(
            rating: _rating,
            ratingLabel: _ratingLabel,
            onRatingChanged: (double value) {
              setState(() => _rating = value);
            },
          ),
          const SizedBox(height: 16),
          _ReviewCommentInput(
            controller: _commentController,
            currentCount: _commentController.text.characters.length,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: UploadImageGrid(
              scene: FileScene.review,
              maxImages: 1,
              uploadLabel: '上传.上传图片'.tr(),
              onChanged: (_) {},
              onUploadedChanged: (List<UploadedImageValue> uploadedImages) {
                _uploadedImages = uploadedImages;
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
    );
  }

  /// 构建底部发布栏，单独控制禁用态颜色与底部安全区留白。
  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _PublishActionButton(
            label: '评价.发布'.tr(),
            enabled: _canPublish && !_isSubmitting,
            onPressed: _handlePublish,
          ),
        ),
      ),
    );
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
        toolbarHeight: 44,
        leadingWidth: 44,
        leading: Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                _showPlaceholder('订单.暂无可返回页面'.tr());
              }
            },
            padding: EdgeInsets.zero,
            splashRadius: 20,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const AppSvgIcon(
              assetPath: 'assets/images/service_detail_back.svg',
              fallback: Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: Color(0xE6000000),
            ),
          ),
        ),
        title: Text(
          '评价.标题'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 17,
            color: const Color(0xE6000000),
          ),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
          children: <Widget>[
            _ReviewOrderCard(args: widget.args),
            const SizedBox(height: 12),
            _buildReviewPanel(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
}

class _ReviewOrderCard extends StatelessWidget {
  const _ReviewOrderCard({required this.args});

  final OrderReviewPageArgs args;

  @override
  /// 构建订单摘要卡片，保持与设计稿一致的边距和信息密度。
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
  /// 构建订单标题与价格区域，右侧价格保持单行紧凑展示。
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: TestStyle.semibold(
              fontSize: 16,
              color: const Color(0xFF262626),
            ),
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
  /// 构建订单信息行，超长内容在右侧省略避免撑破布局。
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          label,
          style: TestStyle.regular(
            fontSize: 12,
            color: const Color(0xFF8C8C8C),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TestStyle.regular(
              fontSize: 12,
              color: const Color(0xFF8C8C8C),
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
  /// 构建评分行，使用固定星级区域宽度来锁定视觉间距。
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Row(
        children: <Widget>[
          Text(
            '评价.服务评价'.tr(),
            style: TestStyle.pingFangRegular(
              fontSize: 13,
              color: const Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 184,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List<Widget>.generate(5, (int index) {
                final double starNumber = index + 1.0;
                late final IconData icon;
                late final Color color;

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

                return SizedBox(
                  width: 24,
                  height: 24,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onRatingChanged(index + 1.0),
                    child: Icon(icon, size: 20, color: color),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
          Text(
            ratingLabel,
            style: TestStyle.pingFangRegular(
              fontSize: 13,
              color: const Color(0xFF8C8C8C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCommentInput extends StatelessWidget {
  const _ReviewCommentInput({
    required this.controller,
    required this.currentCount,
  });

  final TextEditingController controller;
  final int currentCount;

  @override
  /// 构建评论输入区域，固定高度以还原设计稿中的大面积留白。
  Widget build(BuildContext context) {
    return Container(
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
              controller: controller,
              maxLength: 500,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              cursorColor: const Color(0xFF262626),
              decoration: InputDecoration(
                hintText: '评价.写评论'.tr(),
                hintStyle: TestStyle.pingFangRegular(
                  fontSize: 13,
                  color: const Color(0xFF8C8C8C),
                ),
                border: InputBorder.none,
                counterText: '',
                isCollapsed: true,
              ),
              style: TestStyle.pingFangRegular(
                fontSize: 13,
                color: const Color(0xFF262626),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '$currentCount/500',
              style: TestStyle.pingFangRegular(
                fontSize: 12,
                color: const Color(0xFFBFBFBF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishActionButton extends StatelessWidget {
  const _PublishActionButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  /// 构建页面专用发布按钮，单独控制禁用态底色以贴近视觉稿。
  Widget build(BuildContext context) {
    final Color backgroundColor = enabled
        ? const Color(0xFF096DD9)
        : const Color(0xFFA8C7E8);

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(8),
            child: Center(
              // 禁用态保留白字，确保与设计稿中的浅蓝底一致。
              child: Text(
                label,
                style: TestStyle.pingFangMedium(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
