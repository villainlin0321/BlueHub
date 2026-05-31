import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/app_user_avatar.dart';
import '../../data/user_models.dart';
import '../../application/blacklist/blacklist_state.dart';
import '../blacklist_page_styles.dart';

class BlacklistPageView extends StatelessWidget {
  const BlacklistPageView({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onBack,
    required this.onRefresh,
    required this.onRetry,
    required this.onRemoveTap,
  });

  static const String _avatarFallbackAsset =
      'assets/images/order_management_customer_avatar-56586a.png';

  final BlacklistState state;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;
  final VoidCallback onRetry;
  final ValueChanged<UserVO> onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlacklistPageStyles.pageBackground,
      appBar: AppBar(
        backgroundColor: BlacklistPageStyles.navBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.chevron_left,
            color: BlacklistPageStyles.titleColor,
          ),
        ),
        title: Text('我的.黑名单'.tr(), style: BlacklistPageStyles.navTitle),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return _BlacklistErrorState(
        message: state.errorMessage!,
        onRetry: onRetry,
      );
    }

    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          BlacklistPageStyles.horizontalPadding,
          BlacklistPageStyles.topPadding,
          BlacklistPageStyles.horizontalPadding,
          bottomInset + 24,
        ),
        children: <Widget>[
          _BlacklistCountHeader(totalCount: state.totalCount),
          const SizedBox(height: 12),
          if (state.items.isEmpty)
            SizedBox(
              height: 320,
              child: Center(
                child: AppEmptyState(
                  message: '我的.暂无黑名单用户'.tr(),
                  padding: EdgeInsets.symmetric(horizontal: 24),
                ),
              ),
            )
          else
            _BlacklistListCard(
              items: state.items,
              removingUserIds: state.removingUserIds,
              onRemoveTap: onRemoveTap,
            ),
          if (state.items.isNotEmpty)
            _BlacklistLoadMoreFooter(
              isLoadingMore: state.isLoadingMore,
              hasNext: state.hasNext,
            ),
        ],
      ),
    );
  }
}

class _BlacklistCountHeader extends StatelessWidget {
  const _BlacklistCountHeader({required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Text(
      '我的.已拉黑用户统计'.tr(namedArgs: <String, String>{
        'count': totalCount.toString(),
      }),
      style: BlacklistPageStyles.countText,
    );
  }
}

class _BlacklistListCard extends StatelessWidget {
  const _BlacklistListCard({
    required this.items,
    required this.removingUserIds,
    required this.onRemoveTap,
  });

  final List<UserVO> items;
  final Set<int> removingUserIds;
  final ValueChanged<UserVO> onRemoveTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BlacklistPageStyles.cardBackground,
        borderRadius: BorderRadius.circular(BlacklistPageStyles.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: List<Widget>.generate(items.length, (int index) {
            final UserVO user = items[index];
            return Column(
              children: <Widget>[
                _BlacklistUserTile(
                  user: user,
                  isRemoving: removingUserIds.contains(user.userId),
                  onRemoveTap: () => onRemoveTap(user),
                ),
                if (index != items.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: BlacklistPageStyles.divider,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _BlacklistUserTile extends StatelessWidget {
  const _BlacklistUserTile({
    required this.user,
    required this.isRemoving,
    required this.onRemoveTap,
  });

  final UserVO user;
  final bool isRemoving;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    final String nickname = user.nickname.trim().isEmpty
        ? '我的.用户占位昵称'.tr(
            namedArgs: <String, String>{'userId': user.userId.toString()},
          )
        : user.nickname.trim();
    return SizedBox(
      height: BlacklistPageStyles.tileHeight,
      child: Row(
        children: <Widget>[
          _BlacklistAvatar(avatarUrl: user.avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nickname,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BlacklistPageStyles.nickname,
            ),
          ),
          TextButton(
            onPressed: isRemoving ? null : onRemoveTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: BlacklistPageStyles.actionColor,
            ),
            child: Text(
              isRemoving ? '我的.移除中'.tr() : '我的.移除'.tr(),
              style: BlacklistPageStyles.action,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlacklistAvatar extends StatelessWidget {
  const _BlacklistAvatar({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return AppUserAvatar(
      imageUrl: avatarUrl.trim(),
      size: BlacklistPageStyles.avatarSize,
      placeholderAssetPath: BlacklistPageView._avatarFallbackAsset,
    );
  }
}

class _BlacklistLoadMoreFooter extends StatelessWidget {
  const _BlacklistLoadMoreFooter({
    required this.isLoadingMore,
    required this.hasNext,
  });

  final bool isLoadingMore;
  final bool hasNext;

  @override
  Widget build(BuildContext context) {
    final String text = isLoadingMore
        ? '我的.加载中'.tr()
        : hasNext
        ? '我的.上滑加载更多'.tr()
        : '我的.没有更多了'.tr();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text(text, style: BlacklistPageStyles.footer)),
    );
  }
}

class _BlacklistErrorState extends StatelessWidget {
  const _BlacklistErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: BlacklistPageStyles.errorText,
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text('我的.重试'.tr())),
          ],
        ),
      ),
    );
  }
}
