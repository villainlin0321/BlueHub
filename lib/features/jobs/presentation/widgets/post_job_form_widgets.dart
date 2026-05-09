import 'package:flutter/material.dart';

import '../post_job_page_styles.dart';

class PostJobSectionCard extends StatelessWidget {
  const PostJobSectionCard({
    super.key,
    required this.title,
    this.trailing,
    required this.child,
  });

  final String title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: PostJobPageStyles.surface,
        borderRadius: BorderRadius.circular(PostJobPageStyles.cardRadius),
        boxShadow: PostJobPageStyles.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 3,
                  height: 12,
                  color: PostJobPageStyles.primary,
                ),
                const SizedBox(width: 8),
                Text(title, style: PostJobPageStyles.sectionTitle),
                if (trailing != null) ...<Widget>[
                  const SizedBox(width: 8),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class PostJobFieldGroup extends StatelessWidget {
  const PostJobFieldGroup({
    super.key,
    required this.label,
    this.required = true,
    required this.child,
  });

  final String label;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(label, style: PostJobPageStyles.fieldLabel),
            if (required) ...<Widget>[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  color: PostJobPageStyles.required,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class PostJobInputField extends StatelessWidget {
  const PostJobInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final bool multiline = maxLines > 1;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: PostJobPageStyles.inputFill,
        borderRadius: BorderRadius.circular(PostJobPageStyles.fieldRadius),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        minLines: minLines,
        maxLength: maxLength,
        textInputAction: textInputAction,
        onChanged: onChanged,
        buildCounter:
            (
              BuildContext context, {
              required int currentLength,
              required bool isFocused,
              required int? maxLength,
            }) {
              return const SizedBox.shrink();
            },
        style: PostJobPageStyles.optionText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: PostJobPageStyles.placeholder,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          contentPadding: EdgeInsets.fromLTRB(
            12,
            multiline ? 12 : 14,
            12,
            multiline ? 12 : 14,
          ),
        ),
      ),
    );
  }
}

class PostJobRadioOption extends StatelessWidget {
  const PostJobRadioOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _RadioDot(selected: selected),
            const SizedBox(width: 8),
            Text(label, style: PostJobPageStyles.optionText),
          ],
        ),
      ),
    );
  }
}

class PostJobSelectableChip extends StatelessWidget {
  const PostJobSelectableChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = selected
        ? PostJobPageStyles.chipSelectedBorder
        : PostJobPageStyles.chipUnselectedBorder;
    final Color backgroundColor = selected
        ? PostJobPageStyles.chipSelectedBackground
        : PostJobPageStyles.surface;
    final Color textColor = selected
        ? PostJobPageStyles.chipSelectedText
        : PostJobPageStyles.chipUnselectedText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PostJobPageStyles.chipRadius),
        hoverColor: selected
            ? PostJobPageStyles.chipSelectedBackground.withValues(alpha: 0.8)
            : PostJobPageStyles.inputFill,
        focusColor: selected
            ? PostJobPageStyles.chipSelectedBackground.withValues(alpha: 0.9)
            : PostJobPageStyles.inputFill,
        child: Container(
          height: 32,
          constraints: const BoxConstraints(minWidth: 96),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(PostJobPageStyles.chipRadius),
            border: Border.all(color: borderColor),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 18 / 14,
                  ),
                ),
              ),
              if (selected)
                const Positioned(
                  right: -1,
                  bottom: -1,
                  child: _ChipCheckCorner(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? PostJobPageStyles.primary
              : PostJobPageStyles.placeholderText,
          width: 2,
        ),
        color: Colors.white,
      ),
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected ? PostJobPageStyles.primary : Colors.transparent,
        ),
      ),
    );
  }
}

class _ChipCheckCorner extends StatelessWidget {
  const _ChipCheckCorner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: CustomPaint(painter: _ChipCheckPainter()),
    );
  }
}

class _ChipCheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint trianglePaint = Paint()
      ..color = PostJobPageStyles.primary
      ..style = PaintingStyle.fill;

    final Path path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, trianglePaint);

    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path checkPath = Path()
      ..moveTo(size.width * 0.33, size.height * 0.72)
      ..lineTo(size.width * 0.5, size.height * 0.87)
      ..lineTo(size.width * 0.82, size.height * 0.46);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
