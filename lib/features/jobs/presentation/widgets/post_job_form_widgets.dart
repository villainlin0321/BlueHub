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
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

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
        onSubmitted: onSubmitted,
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
        ? PostJobPageStyles.primary
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
          height: 34,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(PostJobPageStyles.chipRadius),
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: <Widget>[
              Positioned.fill(
                child: Center(
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
              ),
              if (selected)
                const Positioned(right: 0, bottom: 0, child: _ChipCheckIcon()),
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

class _ChipCheckIcon extends StatelessWidget {
  const _ChipCheckIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 15,
      height: 12,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(PostJobPageStyles.chipRadius),
        ),
        child: CustomPaint(painter: _ChipCheckIconPainter()),
      ),
    );
  }
}

class _ChipCheckIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = PostJobPageStyles.primary
      ..style = PaintingStyle.fill;

    final Path cornerPath = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(cornerPath, fillPaint);

    final Paint checkPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path iconPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.7)
      ..lineTo(size.width * 0.65, size.height * 0.8)
      ..lineTo(size.width * 0.85, size.height * 0.55);
    canvas.drawPath(iconPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
