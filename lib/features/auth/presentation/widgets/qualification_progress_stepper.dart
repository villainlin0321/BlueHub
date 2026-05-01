import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class QualificationProgressStepper extends StatelessWidget {
  const QualificationProgressStepper({
    super.key,
    required this.labels,
    required this.currentStep,
  });

  final List<String> labels;
  final int currentStep;
  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _inactiveSegmentColor = Color(0x26000000);
  static const double _stepHeight = 46;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
      child: SizedBox(
        height: _stepHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(labels.length, (int index) {
            return Expanded(
              child: _QualificationStepItem(
                label: labels[index],
                number: index + 1,
                state: _stateFor(index),
                showLeftConnector: index > 0,
                showRightConnector: index < labels.length - 1,
                leftConnectorColor: index > 0
                    ? _segmentColor(index - 1)
                    : Colors.transparent,
                rightConnectorColor: index < labels.length - 1
                    ? _segmentColor(index)
                    : Colors.transparent,
              ),
            );
          }),
        ),
      ),
    );
  }

  Color _segmentColor(int segmentIndex) {
    return _stateFor(segmentIndex) == _QualificationStepState.completed
        ? _activeColor
        : _inactiveSegmentColor;
  }

  _QualificationStepState _stateFor(int index) {
    if (index < currentStep - 1) {
      return _QualificationStepState.completed;
    }
    if (index == currentStep - 1) {
      return _QualificationStepState.current;
    }
    return _QualificationStepState.pending;
  }
}

enum _QualificationStepState { completed, current, pending }

class _QualificationStepItem extends StatelessWidget {
  const _QualificationStepItem({
    required this.label,
    required this.number,
    required this.state,
    required this.showLeftConnector,
    required this.showRightConnector,
    required this.leftConnectorColor,
    required this.rightConnectorColor,
  });

  final String label;
  final int number;
  final _QualificationStepState state;
  final bool showLeftConnector;
  final bool showRightConnector;
  final Color leftConnectorColor;
  final Color rightConnectorColor;

  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _pendingLabelColor = Color(0xFF8C8C8C);
  static const Color _completedLabelColor = Color(0xFF262626);
  static const double _stepHeight = 46;
  static const double _trackHeight = 20;
  static const double _indicatorSize = 20;
  static const double _connectorGap = 6;
  static const double _labelTopSpacing = 8;
  static const double _labelFontSize = 11;
  static const double _labelHeight = 18 / 11;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: _trackHeight,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: showLeftConnector
                      ? Container(height: 1, color: leftConnectorColor)
                      : null,
                ),
              ),
              const SizedBox(width: _connectorGap),
              _QualificationStepIndicator(number: number, state: state),
              const SizedBox(width: _connectorGap),
              Expanded(
                child: Center(
                  child: showRightConnector
                      ? Container(height: 1, color: rightConnectorColor)
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: _labelTopSpacing),
        SizedBox(
          height: _stepHeight - _indicatorSize - _labelTopSpacing,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: switch (state) {
                _QualificationStepState.pending => _pendingLabelColor,
                _QualificationStepState.current => _activeColor,
                _QualificationStepState.completed => _completedLabelColor,
              },
              fontWeight: state == _QualificationStepState.current
                  ? FontWeight.w500
                  : FontWeight.w400,
              fontSize: _labelFontSize,
              height: _labelHeight,
            ),
          ),
        ),
      ],
    );
  }
}

class _QualificationStepIndicator extends StatelessWidget {
  const _QualificationStepIndicator({
    required this.number,
    required this.state,
  });

  final int number;
  final _QualificationStepState state;

  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _inactiveColor = Color(0xFFD9D9D9);
  static const double _size = 20;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _QualificationStepState.completed:
        return Container(
          width: _size,
          height: _size,
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
      case _QualificationStepState.current:
        return _QualificationNumberIndicator(
          number: number,
          backgroundColor: _activeColor,
        );
      case _QualificationStepState.pending:
        return _QualificationNumberIndicator(
          number: number,
          backgroundColor: _inactiveColor,
        );
    }
  }
}

class _QualificationNumberIndicator extends StatelessWidget {
  const _QualificationNumberIndicator({
    required this.number,
    required this.backgroundColor,
  });

  final int number;
  final Color backgroundColor;

  static const double _size = 20;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _size,
      height: _size,
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
