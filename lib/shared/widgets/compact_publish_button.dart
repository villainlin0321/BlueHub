import 'package:flutter/material.dart';

import 'package:europepass/shared/ui/test_style.dart';

class CompactPublishButton extends StatelessWidget {
  const CompactPublishButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 30,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF096DD9),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.fromLTRB(9, 9, 11, 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.add, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TestStyle.pingFangMedium(
                fontSize: 13,
                color: Colors.white,
              ).copyWith(letterSpacing: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
