import 'package:flutter/material.dart';

import '../../data/my_applications_models.dart';

class MyApplicationCard extends StatelessWidget {
  const MyApplicationCard({
    super.key,
    required this.item,
    this.onActionTap,
  });

  final MyApplicationItem item;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final statusColors = _statusColorsFor(item.status);
    final isApplied = item.status == MyApplicationStatus.applied;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SizedBox(
        height: 128,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF262626),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    item.salary,
                    style: const TextStyle(
                      color: Color(0xFFFE5815),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 24 / 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompanyRow(
                      companyName: item.companyName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _LocationRow(locationText: item.locationText),
                ],
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  _StatusTag(
                    label: item.status.label,
                    backgroundColor: statusColors.$1,
                    foregroundColor: statusColors.$2,
                    borderColor: statusColors.$3,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.updatedText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 16 / 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    label: item.actionLabel,
                    filled: !isApplied,
                    onPressed: onActionTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, Color, Color?) _statusColorsFor(MyApplicationStatus status) {
    switch (status) {
      case MyApplicationStatus.applied:
        return (
          Colors.white,
          const Color(0xFF546D96),
          const Color(0xFFA3AFD4),
        );
      case MyApplicationStatus.viewed:
        return (
          const Color(0xFFEDF5FF),
          const Color(0xFF386EF8),
          null,
        );
      case MyApplicationStatus.interview:
        return (
          const Color(0xFFEDF5FF),
          const Color(0xFF386EF8),
          null,
        );
    }
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(3),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w400,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class _CompanyRow extends StatelessWidget {
  const _CompanyRow({
    required this.companyName,
  });

  final String companyName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFFD8D8D8),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.person_rounded,
            size: 11,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            companyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF595959),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 16 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationRow extends StatelessWidget {
  const _LocationRow({required this.locationText});

  final String locationText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Icon(
          Icons.location_on_outlined,
          size: 16,
          color: Color(0xFFBCBCBC),
        ),
        const SizedBox(width: 4),
        Text(
          locationText,
          style: const TextStyle(
            color: Color(0xFF595959),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = filled ? const Color(0xFF096DD9) : Colors.white;
    final foregroundColor = filled ? Colors.white : const Color(0xFF262626);
    final borderColor = filled ? const Color(0xFF096DD9) : const Color(0xFFD9D9D9);

    return SizedBox(
      width: 77,
      height: 28,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: filled
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x26096DD9),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: foregroundColor,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 12 / 12,
            ),
          ),
        ),
      ),
    );
  }
}
