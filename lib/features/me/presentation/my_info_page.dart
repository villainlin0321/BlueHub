import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_session_provider.dart';
import 'current_user_view_data.dart';

/// 我的信息页：展示当前登录用户的基础资料。
class MyInfoPage extends ConsumerWidget {
  const MyInfoPage({super.key});

  static const String _avatarAsset = 'assets/images/mou4gf12-gby6i3c.png';

  @override
  /// 构建“我的信息”页面，并复用登录态中的最新用户资料。
  Widget build(BuildContext context, WidgetRef ref) {
    final CurrentUserViewData userViewData = CurrentUserViewData.fromAuthUser(
      ref.watch(authSessionProvider).user,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _MyInfoHeader(onBackTap: context.pop),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: <Widget>[
                      _InfoAvatarRow(
                        label: '头像',
                        avatarUrl: userViewData.avatarUrl,
                        fallbackAssetPath: _avatarAsset,
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                      _InfoValueRow(
                        label: '出生日期',
                        value: userViewData.birthdayText,
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                      _InfoValueRow(
                        label: '性别',
                        value: userViewData.genderText,
                      ),
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF0F0F0),
                      ),
                      _InfoValueRow(
                        label: '手机号',
                        value: userViewData.maskedPhone,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyInfoHeader extends StatelessWidget {
  const _MyInfoHeader({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  /// 构建顶部返回栏，保持与设计稿一致的标题与交互位置。
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
            ),
          ),
          const Text(
            '我的信息',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoAvatarRow extends StatelessWidget {
  const _InfoAvatarRow({
    required this.label,
    required this.avatarUrl,
    required this.fallbackAssetPath,
  });

  final String label;
  final String avatarUrl;
  final String fallbackAssetPath;

  @override
  /// 构建头像行，优先展示服务端头像，失败时回退到本地占位图。
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
          const Spacer(),
          _MyInfoAvatar(
            avatarUrl: avatarUrl,
            fallbackAssetPath: fallbackAssetPath,
            size: 40,
          ),
        ],
      ),
    );
  }
}

class _InfoValueRow extends StatelessWidget {
  const _InfoValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  /// 构建基础资料行，统一处理右侧值与箭头样式。
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF8C8C8C),
              fontSize: 16,
              height: 22 / 16,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBFBFBF)),
        ],
      ),
    );
  }
}

class _MyInfoAvatar extends StatelessWidget {
  const _MyInfoAvatar({
    required this.avatarUrl,
    required this.fallbackAssetPath,
    required this.size,
  });

  final String avatarUrl;
  final String fallbackAssetPath;
  final double size;

  @override
  /// 构建圆形头像，并兼容加载中与加载失败场景。
  Widget build(BuildContext context) {
    final Widget fallback = ClipOval(
      child: Image.asset(
        fallbackAssetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
    if (avatarUrl.isEmpty) {
      return fallback;
    }

    return ClipOval(
      child: Image.network(
        avatarUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
        loadingBuilder:
            (BuildContext context, Widget child, ImageChunkEvent? event) {
              if (event == null) {
                return child;
              }
              return fallback;
            },
      ),
    );
  }
}
