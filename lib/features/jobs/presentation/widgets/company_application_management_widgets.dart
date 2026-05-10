import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../company_application_management_styles.dart';

class CompanyApplicationCardData {
  const CompanyApplicationCardData({
    required this.positionTitle,
    required this.matchText,
    required this.name,
    required this.ageGender,
    required this.tags,
    required this.submittedText,
    required this.secondaryActionLabel,
    required this.backgroundAssetPath,
  });

  final String positionTitle;
  final String matchText;
  final String name;
  final String ageGender;
  final List<String> tags;
  final String submittedText;
  final String secondaryActionLabel;
  final String backgroundAssetPath;
}

class CompanyApplicationTopBar extends StatelessWidget {
  const CompanyApplicationTopBar({
    super.key,
    required this.title,
    required this.onBackTap,
    required this.onSearchTap,
  });

  final String title;
  final VoidCallback onBackTap;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Container(
      color: CompanyApplicationManagementStyles.surface,
      padding: EdgeInsets.fromLTRB(8, topPadding + 4, 8, 4),
      child: SizedBox(
        height: 44,
        child: Row(
          children: <Widget>[
            _TopBarIconButton(
              assetPath: CompanyApplicationManagementStyles.backAssetPath,
              fallbackIcon: Icons.arrow_back_ios_new_rounded,
              fallbackSize: 18,
              onTap: onBackTap,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 24 / 17,
                ),
              ),
            ),
            _TopBarIconButton(
              assetPath: CompanyApplicationManagementStyles.searchAssetPath,
              fallbackIcon: Icons.search_rounded,
              fallbackSize: 20,
              onTap: onSearchTap,
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyApplicationTabBar extends StatelessWidget {
  const CompanyApplicationTabBar({super.key, required this.tabs});

  final List<String> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: CompanyApplicationManagementStyles.surface,
        border: Border(
          bottom: BorderSide(
            color: CompanyApplicationManagementStyles.divider,
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        tabs: tabs
            .map((String label) => Tab(height: 48, text: label))
            .toList(growable: false),
        labelColor: CompanyApplicationManagementStyles.primary,
        unselectedLabelColor: CompanyApplicationManagementStyles.textPrimary,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 22 / 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 22 / 14,
        ),
        indicatorSize: TabBarIndicatorSize.label,
        indicatorColor: CompanyApplicationManagementStyles.primary,
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}

class CompanyApplicationJobFilterBar extends StatelessWidget {
  const CompanyApplicationJobFilterBar({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CompanyApplicationManagementStyles.surface,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 7),
      child: Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          overlayColor: const WidgetStatePropertyAll(
            CompanyApplicationManagementStyles.actionOverlay,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF171A1D),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(width: 4),
                Image.asset(
                  CompanyApplicationManagementStyles.filterArrowAssetPath,
                  width: 12,
                  height: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CompanyApplicationListStateView extends StatelessWidget {
  const CompanyApplicationListStateView({
    super.key,
    required this.message,
    required this.icon,
    this.buttonLabel,
    this.onTap,
  });

  final String message;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        24,
        96,
        24,
        MediaQuery.paddingOf(context).bottom + 24,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: CompanyApplicationManagementStyles.surface,
            borderRadius: BorderRadius.circular(
              CompanyApplicationManagementStyles.cardRadius,
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(
                icon,
                size: 34,
                color: CompanyApplicationManagementStyles.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: CompanyApplicationManagementStyles.textSecondary,
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
              if (buttonLabel != null && onTap != null) ...<Widget>[
                const SizedBox(height: 14),
                TextButton(onPressed: onTap, child: Text(buttonLabel!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CompanyApplicationCard extends StatelessWidget {
  const CompanyApplicationCard({
    super.key,
    required this.data,
    required this.onViewResumeTap,
    required this.onSecondaryActionTap,
  });

  final CompanyApplicationCardData data;
  final VoidCallback onViewResumeTap;
  final VoidCallback onSecondaryActionTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        CompanyApplicationManagementStyles.cardRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SvgPicture.asset(
                data.backgroundAssetPath,
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  CompanyApplicationManagementStyles.cardRadius,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: CompanyApplicationManagementStyles.cardShadow,
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CardTopRow(data: data),
                    const SizedBox(height: 14),
                    _CandidateInfoSection(data: data),
                    const SizedBox(height: 20),
                    _CardFooter(
                      data: data,
                      onViewResumeTap: onViewResumeTap,
                      onSecondaryActionTap: onSecondaryActionTap,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTopRow extends StatelessWidget {
  const _CardTopRow({required this.data});

  final CompanyApplicationCardData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: RichText(
            text: TextSpan(
              children: <InlineSpan>[
                const TextSpan(
                  text: '投递岗位: ',
                  style: TextStyle(
                    color: CompanyApplicationManagementStyles.textSecondary,
                    fontSize: 14,
                    height: 16 / 14,
                  ),
                ),
                TextSpan(
                  text: data.positionTitle,
                  style: const TextStyle(
                    color: CompanyApplicationManagementStyles.textPrimary,
                    fontSize: 14,
                    height: 16 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: data.matchText,
                style: const TextStyle(
                  color: CompanyApplicationManagementStyles.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 21 / 16,
                ),
              ),
              const TextSpan(
                text: ' 匹配',
                style: TextStyle(
                  color: CompanyApplicationManagementStyles.primary,
                  fontSize: 10,
                  height: 14 / 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CandidateInfoSection extends StatelessWidget {
  const _CandidateInfoSection({required this.data});

  final CompanyApplicationCardData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Image.asset(
          CompanyApplicationManagementStyles.avatarPlaceholderAssetPath,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Flexible(
                    child: Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CompanyApplicationManagementStyles.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 24 / 16,
                      ),
                    ),
                  ),
                  if (data.ageGender.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        data.ageGender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                              CompanyApplicationManagementStyles.textSecondary,
                          fontSize: 12,
                          height: 18 / 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: data.tags
                    .map((String label) => CompanyApplicationTag(label: label))
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.data,
    required this.onViewResumeTap,
    required this.onSecondaryActionTap,
  });

  final CompanyApplicationCardData data;
  final VoidCallback onViewResumeTap;
  final VoidCallback onSecondaryActionTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Widget actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CompanyApplicationActionButton(
              label: '查看简历',
              onTap: onViewResumeTap,
            ),
            const SizedBox(width: 8),
            CompanyApplicationActionButton(
              label: data.secondaryActionLabel,
              primary: true,
              onTap: onSecondaryActionTap,
            ),
          ],
        );

        if (constraints.maxWidth < 320) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                data.submittedText,
                style: const TextStyle(
                  color: CompanyApplicationManagementStyles.textSecondary,
                  fontSize: 12,
                  height: 16 / 12,
                ),
              ),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        }

        return Row(
          children: <Widget>[
            Expanded(
              child: Text(
                data.submittedText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CompanyApplicationManagementStyles.textSecondary,
                  fontSize: 12,
                  height: 16 / 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            actions,
          ],
        );
      },
    );
  }
}

class CompanyApplicationTag extends StatelessWidget {
  const CompanyApplicationTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: CompanyApplicationManagementStyles.tagBorder),
        borderRadius: BorderRadius.circular(
          CompanyApplicationManagementStyles.tagRadius,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: CompanyApplicationManagementStyles.tagText,
          fontSize: 11,
          height: 12 / 11,
        ),
      ),
    );
  }
}

class CompanyApplicationActionButton extends StatelessWidget {
  const CompanyApplicationActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = primary
        ? Colors.white
        : CompanyApplicationManagementStyles.textPrimary;

    return Material(
      color: primary
          ? CompanyApplicationManagementStyles.primary
          : CompanyApplicationManagementStyles.surface,
      borderRadius: BorderRadius.circular(
        CompanyApplicationManagementStyles.buttonRadius,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          CompanyApplicationManagementStyles.buttonRadius,
        ),
        overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (!states.contains(WidgetState.hovered) &&
              !states.contains(WidgetState.focused) &&
              !states.contains(WidgetState.pressed)) {
            return null;
          }
          return primary
              ? Colors.white.withValues(alpha: 0.12)
              : CompanyApplicationManagementStyles.actionOverlay;
        }),
        child: Ink(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              CompanyApplicationManagementStyles.buttonRadius,
            ),
            border: primary
                ? null
                : Border.all(
                    color: CompanyApplicationManagementStyles.ghostBorder,
                  ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 12 / 12,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackSize,
    required this.onTap,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double fallbackSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        overlayColor: const WidgetStatePropertyAll(
          CompanyApplicationManagementStyles.actionOverlay,
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: SvgPicture.asset(
              assetPath,
              width: fallbackSize,
              height: fallbackSize,
              placeholderBuilder: (_) => Icon(
                fallbackIcon,
                size: fallbackSize,
                color: CompanyApplicationManagementStyles.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
