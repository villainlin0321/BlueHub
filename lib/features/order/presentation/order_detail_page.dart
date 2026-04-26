import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/primary_button.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key});

  static const List<_OrderStep> _steps = <_OrderStep>[
    _OrderStep(label: '提交订单', state: _OrderStepState.completed),
    _OrderStep(label: '支付费用', state: _OrderStepState.completed),
    _OrderStep(label: '上传材料', state: _OrderStepState.current, number: 3),
    _OrderStep(label: '材料审核', state: _OrderStepState.pending, number: 4),
    _OrderStep(label: '使馆递交', state: _OrderStepState.pending, number: 5),
    _OrderStep(label: '签证出签', state: _OrderStepState.pending, number: 6),
  ];

  static const List<_MaterialRequirement> _requirements =
      <_MaterialRequirement>[
        _MaterialRequirement(title: '护照原件及复印件', required: true),
        _MaterialRequirement(title: '厨师资格证公证件', required: true),
        _MaterialRequirement(title: '德语语言证明'),
      ];

  void _showPlaceholder(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              _showPlaceholder(context, '暂无可返回页面');
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
          '订单详情',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => _showPlaceholder(context, '联系商家（占位）'),
            child: Text(
              '联系商家',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF262626),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const _OrderProgressStepper(steps: _steps),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _OrderInfoCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: _MaterialUploadCard(
              requirements: _requirements,
              onPreviewTap: (title) =>
                  _showPlaceholder(context, '$title 查看样例（占位）'),
              onUploadTap: (title) =>
                  _showPlaceholder(context, '$title 上传文件（占位）'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: _BottomSubmitBar(
        onPressed: () => _showPlaceholder(context, '提交材料（占位）'),
      ),
    );
  }
}

class _OrderProgressStepper extends StatelessWidget {
  const _OrderProgressStepper({required this.steps});

  final List<_OrderStep> steps;

  static const double _stepWidth = 50;
  static const double _stepHeight = 46;
  static const double _indicatorSize = 20;
  static const double _connectorGap = 6;
  static const double _connectorWidth = 9;
  static const double _separatorWidth = 16;
  static const double _trackHeight = 20;

  Color _segmentColor(int segmentIndex) {
    return segmentIndex < 2
        ? const Color(0xFF096DD9)
        : Colors.black.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: steps.length,
        separatorBuilder: (context, index) {
          return SizedBox(
            width: _separatorWidth,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _trackHeight,
                child: Center(
                  child: Container(
                    width: _separatorWidth,
                    height: 1,
                    color: _segmentColor(index),
                  ),
                ),
              ),
            ),
          );
        },
        itemBuilder: (context, index) {
          final step = steps[index];
          final showLeftConnector = index > 0;
          final showRightConnector = index < steps.length - 1;

          return SizedBox(
            width: _stepWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: _stepWidth,
                  height: _trackHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: _trackHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: _connectorWidth,
                            child: Center(
                              child: showLeftConnector
                                  ? Container(
                                      width: _connectorWidth,
                                      height: 1,
                                      color: _segmentColor(index - 1),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: _connectorGap),
                          _StepIndicator(step: step),
                          const SizedBox(width: _connectorGap),
                          SizedBox(
                            width: _connectorWidth,
                            child: Center(
                              child: showRightConnector
                                  ? Container(
                                      width: _connectorWidth,
                                      height: 1,
                                      color: _segmentColor(index),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: _stepWidth,
                  height: _stepHeight - _indicatorSize - 8,
                  child: Text(
                    step.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: step.state == _OrderStepState.pending
                          ? const Color(0xFF8C8C8C)
                          : step.state == _OrderStepState.current
                              ? const Color(0xFF096DD9)
                              : const Color(0xFF262626),
                      fontWeight: step.state == _OrderStepState.current
                          ? FontWeight.w500
                          : FontWeight.w400,
                      fontSize: 11,
                      height: 18 / 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _OrderStep step;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case _OrderStepState.completed:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF096DD9), width: 1.4),
            color: Colors.white,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/images/order_detail_step_done.svg',
            width: 10,
            height: 8,
          ),
        );
      case _OrderStepState.current:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF096DD9),
          ),
          alignment: Alignment.center,
          child: Text(
            '${step.number}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
      case _OrderStepState.pending:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD9D9D9),
          ),
          alignment: Alignment.center,
          child: Text(
            '${step.number}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
    }
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '德国厨师专属工作签证',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: Color(0xFF262626),
            ),
          ),
          SizedBox(height: 12),
          _OrderInfoRow(label: '服务商', value: '中欧出海签证服务有限公司'),
          SizedBox(height: 8),
          _OrderInfoRow(label: '套餐类型', value: '基础套餐'),
          SizedBox(height: 8),
          _OrderInfoRow(label: '套餐价格', value: '¥15,000'),
          SizedBox(height: 8),
          _OrderInfoRow(label: '订单号', value: 'CLSKJ98793120238'),
        ],
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({required this.label, required this.value});

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
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 18 / 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialUploadCard extends StatelessWidget {
  const _MaterialUploadCard({
    required this.requirements,
    required this.onPreviewTap,
    required this.onUploadTap,
  });

  final List<_MaterialRequirement> requirements;
  final ValueChanged<String> onPreviewTap;
  final ValueChanged<String> onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List<Widget>.generate(requirements.length, (index) {
          final item = requirements[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == requirements.length - 1 ? 0 : 20,
            ),
            child: _MaterialUploadItem(
              requirement: item,
              onPreviewTap: () => onPreviewTap(item.title),
              onUploadTap: () => onUploadTap(item.title),
            ),
          );
        }),
      ),
    );
  }
}

class _MaterialUploadItem extends StatelessWidget {
  const _MaterialUploadItem({
    required this.requirement,
    required this.onPreviewTap,
    required this.onUploadTap,
  });

  final _MaterialRequirement requirement;
  final VoidCallback onPreviewTap;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      requirement.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF171A1D),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 22 / 14,
                      ),
                    ),
                  ),
                  if (requirement.required) ...<Widget>[
                    const SizedBox(width: 3),
                    SvgPicture.asset(
                      'assets/images/order_detail_required.svg',
                      width: 6,
                      height: 6,
                    ),
                  ],
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onPreviewTap,
              child: Text(
                '查看样例',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF096DD9),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  height: 22 / 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _UploadPlaceholder(onTap: onUploadTap),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/images/order_detail_upload_add.svg',
                  width: 12,
                  height: 12,
                ),
                const SizedBox(width: 8),
                Text(
                  '上传文件',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF171A1D),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomSubmitBar extends StatelessWidget {
  const _BottomSubmitBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFF0F0F0),
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: Opacity(
            opacity: 0.3,
            child: PrimaryButton(
              label: '提交材料',
              onPressed: onPressed,
              enabled: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStep {
  const _OrderStep({required this.label, required this.state, this.number});

  final String label;
  final _OrderStepState state;
  final int? number;
}

enum _OrderStepState { completed, current, pending }

class _MaterialRequirement {
  const _MaterialRequirement({required this.title, this.required = false});

  final String title;
  final bool required;
}
