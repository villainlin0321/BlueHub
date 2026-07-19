import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 记录一次会话过期事件，利用递增版本号保证重复原因也能触发监听。
class AuthSessionExpiryEvent {
  const AuthSessionExpiryEvent({required this.version, required this.reason});

  final int version;
  final String reason;
}

/// 供网络层派发“登录已过期”事件，避免请求层直接依赖页面导航。
class AuthSessionExpiryNotifier extends Notifier<AuthSessionExpiryEvent?> {
  @override
  AuthSessionExpiryEvent? build() => null;

  void notifyExpired({required String reason}) {
    final int nextVersion = (state?.version ?? 0) + 1;
    state = AuthSessionExpiryEvent(version: nextVersion, reason: reason);
  }
}

final authSessionExpiryProvider =
    NotifierProvider<AuthSessionExpiryNotifier, AuthSessionExpiryEvent?>(
      AuthSessionExpiryNotifier.new,
    );
