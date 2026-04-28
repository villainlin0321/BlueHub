import 'package:flutter/material.dart';

class QualificationProgressStepper extends StatelessWidget {
  const QualificationProgressStepper({
    super.key,
    required this.labels,
    required this.currentStep,
  });

  final List<String> labels;
  final int currentStep;

  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _inactiveLineColor = Color(0x26000000);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              for (int index = 0; index < labels.length; index++) ...<Widget>[
                _StepperDot(
                  number: index + 1,
                  state: _stateFor(index),
                ),
                if (index < labels.length - 1)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Container(
                        height: 1,
                        color: index < currentStep - 1
                            ? _activeColor
                            : _inactiveLineColor,
                      ),
                    ),
                  ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              for (int index = 0; index < labels.length; index++)
                SizedBox(
                  width: 64,
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index == currentStep - 1
                          ? _activeColor
                          : const Color(0xFF8C8C8C),
                      fontSize: 12,
                      fontWeight: index == currentStep - 1
                          ? FontWeight.w500
                          : FontWeight.w400,
                      height: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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

class _StepperDot extends StatelessWidget {
  const _StepperDot({
    required this.number,
    required this.state,
  });

  final int number;
  final _QualificationStepState state;

  static const Color _activeColor = Color(0xFF096DD9);
  static const Color _inactiveColor = Color(0xFFD9D9D9);

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _QualificationStepState.completed:
        return _buildNumberDot(_activeColor);
      case _QualificationStepState.current:
        return _buildNumberDot(_activeColor);
      case _QualificationStepState.pending:
        return _buildNumberDot(_inactiveColor);
    }
  }

  Widget _buildNumberDot(Color backgroundColor) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
    );
  }
}
