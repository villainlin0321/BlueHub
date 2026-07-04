import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../shared/widgets/app_user_avatar.dart';
import '../company_application_management_styles.dart';

import 'package:europepass/shared/ui/test_style.dart';
class CompanyApplicationCardData {
  const CompanyApplicationCardData({
    required this.positionTitle,
    required this.matchText,
    required this.avatarUrl,
    required this.name,
    required this.ageGender,
    required this.tags,
    required this.submittedText,
    required this.secondaryActionLabel,
  });

  final String positionTitle;
  final String matchText;
  final String avatarUrl;
  final String name;
  final String ageGender;
  final List<String> tags;
  final String submittedText;
  final String secondaryActionLabel;
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
                style: TestStyle.semibold(fontSize: 17, color: Colors.black),
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
        labelStyle: TestStyle.medium(fontSize: 14),
        unselectedLabelStyle: TestStyle.regular(fontSize: 14),
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
                  style: TestStyle.regular(fontSize: 14, color: Color(0xFF171A1D)),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
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
    final BorderRadius borderRadius = BorderRadius.circular(
      CompanyApplicationManagementStyles.cardRadius,
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: CompanyApplicationManagementStyles.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.8, sigmaY: 6.8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.72),
                width: 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.95),
                  Colors.white.withValues(alpha: 0.88),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _CardTopRow(data: data),
                    const SizedBox(height: 18),
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
          ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text.rich(
            TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: '招聘.投递岗位'.tr(namedArgs: {'title': data.positionTitle}),
                  style: TestStyle.pingFangRegular(fontSize: 14, color: CompanyApplicationManagementStyles.textPrimary),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              data.matchText,
              style: TestStyle.medium(fontSize: 16, color: CompanyApplicationManagementStyles.primary),
            ),
            const SizedBox(width: 2),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '招聘.匹配度'.tr(),
                style: TestStyle.pingFangRegular(fontSize: 10, color: CompanyApplicationManagementStyles.primary),
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AppUserAvatar(
          imageUrl: data.avatarUrl,
          size: 40,
          placeholderAssetPath:
              CompanyApplicationManagementStyles.avatarPlaceholderAssetPath,
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
                      style: TestStyle.medium(fontSize: 16, color: CompanyApplicationManagementStyles.textPrimary),
                    ),
                  ),
                  if (data.ageGender.isNotEmpty) ...<Widget>[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        data.ageGender,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TestStyle.regular(fontSize: 12, color: CompanyApplicationManagementStyles.textSecondary),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
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
    final Widget actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CompanyApplicationActionButton(
          label: '招聘.查看简历'.tr(),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          data.submittedText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TestStyle.regular(fontSize: 12, color: CompanyApplicationManagementStyles.textSecondary),
        ),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }
}

class CompanyApplicationTag extends StatelessWidget {
  const CompanyApplicationTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: CompanyApplicationManagementStyles.tagBorder,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(
          CompanyApplicationManagementStyles.tagRadius,
        ),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 11, color: CompanyApplicationManagementStyles.tagText),
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
          : Colors.white,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 77),
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
                style: TestStyle.regular(fontSize: 12, color: foregroundColor, letterSpacing: 0.2),
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
