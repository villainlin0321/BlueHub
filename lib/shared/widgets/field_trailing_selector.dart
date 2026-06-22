import 'package:flutter/material.dart';

class FieldTrailingSelector extends StatelessWidget {
  const FieldTrailingSelector({
    super.key,
    required this.label,
    required this.onTap,
    required this.textStyle,
    this.iconColor = Colors.black,
  });

  final String label;
  final VoidCallback onTap;
  final TextStyle textStyle;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(label, style: textStyle),
              const SizedBox(width: 6),
              RotatedBox(
                quarterTurns: 1,
                child: Icon(
                  Icons.keyboard_arrow_right,
                  size: 14,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
