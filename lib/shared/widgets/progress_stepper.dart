import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProgressStepper extends StatelessWidget {
  const ProgressStepper({
    super.key,
    required this.steps,
    this.stepWidth = 50,
    this.stepHeight = 46,
    this.indicatorSize = 20,
    this.connectorGap = 6,
    this.connectorWidth = 9,
    this.separatorWidth = 16,
    this.trackHeight = 20,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 15),
  });

  final List<ProgressStep> steps;
  final double stepWidth;
  final double stepHeight;
  final double indicatorSize;
  final double connectorGap;
  final double connectorWidth;
  final double separatorWidth;
  final double trackHeight;
  final EdgeInsetsGeometry horizontalPadding;

  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _pendingLabelColor = Color(0xFF8C8C8C);
  static const Color _completedLabelColor = Color(0xFF262626);
  static const Color _inactiveSegmentColor = Color(0x26000000);

  Color _segmentColor(int segmentIndex) {
    return steps[segmentIndex].state == ProgressStepState.completed
        ? _activeColor
        : _inactiveSegmentColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: stepHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: horizontalPadding,
        itemCount: steps.length,
        separatorBuilder: (BuildContext context, int index) {
          return SizedBox(
            width: separatorWidth,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: trackHeight,
                child: Center(
                  child: Container(
                    width: separatorWidth,
                    height: 1,
                    color: _segmentColor(index),
                  ),
                ),
              ),
            ),
          );
        },
        itemBuilder: (BuildContext context, int index) {
          final ProgressStep step = steps[index];
          final bool showLeftConnector = index > 0;
          final bool showRightConnector = index < steps.length - 1;

          return SizedBox(
            width: stepWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: stepWidth,
                  height: trackHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: trackHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: connectorWidth,
                            child: Center(
                              child: showLeftConnector
                                  ? Container(
                                      width: connectorWidth,
                                      height: 1,
                                      color: _segmentColor(index - 1),
                                    )
                                  : null,
                            ),
                          ),
                          SizedBox(width: connectorGap),
                          _StepIndicator(
                            step: step,
                            number: step.number ?? index + 1,
                            size: indicatorSize,
                          ),
                          SizedBox(width: connectorGap),
                          SizedBox(
                            width: connectorWidth,
                            child: Center(
                              child: showRightConnector
                                  ? Container(
                                      width: connectorWidth,
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
                  width: stepWidth,
                  height: stepHeight - indicatorSize - 8,
                  child: Text(
                    step.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: switch (step.state) {
                        ProgressStepState.pending => _pendingLabelColor,
                        ProgressStepState.current => _activeColor,
                        ProgressStepState.completed => _completedLabelColor,
                      },
                      fontWeight: step.state == ProgressStepState.current
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

class ProgressStep {
  const ProgressStep({required this.label, required this.state, this.number});

  final String label;
  final ProgressStepState state;
  final int? number;
}

enum ProgressStepState { completed, current, pending }

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.number,
    required this.size,
  });

  final ProgressStep step;
  final int number;
  final double size;

  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _inactiveColor = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case ProgressStepState.completed:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _activeColor, width: 1.4),
            color: Colors.white,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/images/order_detail_step_done.svg',
            width: 10,
            height: 8,
          ),
        );
      case ProgressStepState.current:
        return _NumberIndicator(
          number: number,
          size: size,
          backgroundColor: _activeColor,
        );
      case ProgressStepState.pending:
        return _NumberIndicator(
          number: number,
          size: size,
          backgroundColor: _inactiveColor,
        );
    }
  }
}

class _NumberIndicator extends StatelessWidget {
  const _NumberIndicator({
    required this.number,
    required this.size,
    required this.backgroundColor,
  });

  final int number;
  final double size;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: backgroundColor),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
