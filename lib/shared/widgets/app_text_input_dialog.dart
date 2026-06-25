import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_dialog.dart';

const String _kAppTextInputDialogClearIconAsset =
    'assets/images/ai_history_rename_clear.svg';

Future<String?> showAppTextInputDialog({
  required BuildContext context,
  required String title,
  String initialValue = '',
  String hintText = '',
  String? cancelLabel,
  String? confirmLabel,
}) {
  return showAppDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return _AppTextInputDialog(
        title: title,
        initialValue: initialValue,
        hintText: hintText,
        cancelLabel: cancelLabel ?? '通用.取消'.tr(),
        confirmLabel: confirmLabel ?? '通用.完成'.tr(),
        onCancel: () => Navigator.of(dialogContext).pop(),
        onComplete: (String value) =>
            Navigator.of(dialogContext).pop(value.trim()),
      );
    },
  );
}

class _AppTextInputDialog extends StatefulWidget {
  const _AppTextInputDialog({
    required this.title,
    required this.initialValue,
    required this.hintText,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.onCancel,
    required this.onComplete,
  });

  final String title;
  final String initialValue;
  final String hintText;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback onCancel;
  final ValueChanged<String> onComplete;

  @override
  State<_AppTextInputDialog> createState() => _AppTextInputDialogState();
}

class _AppTextInputDialogState extends State<_AppTextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 296),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
              const SizedBox(height: 16),
              _AppTextInputField(
                controller: _controller,
                hintText: widget.hintText,
                onSubmitted: (_) => widget.onComplete(_controller.text),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _AppTextInputButton(
                      label: widget.cancelLabel,
                      isPrimary: false,
                      onTap: widget.onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _AppTextInputButton(
                      label: widget.confirmLabel,
                      isPrimary: true,
                      onTap: () => widget.onComplete(_controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppTextInputField extends StatelessWidget {
  const _AppTextInputField({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (BuildContext context, TextEditingValue value, Widget? child) {
        final bool canClear = value.text.isNotEmpty;
        return Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: Color(0xFF262626),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 20 / 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IgnorePointer(
                ignoring: !canClear,
                child: Opacity(
                  opacity: canClear ? 1 : 0,
                  child: GestureDetector(
                    onTap: () => controller.clear(),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: SvgPicture.asset(
                        _kAppTextInputDialogClearIconAsset,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AppTextInputButton extends StatelessWidget {
  const _AppTextInputButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Material(
        color: isPrimary ? const Color(0xFF096DD9) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isPrimary
                ? const Color(0xFF096DD9)
                : const Color(0xFFD9D9D9),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : const Color(0xFF262626),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
