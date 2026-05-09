import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/logging/app_logger.dart';

enum ShellRole { jobSeeker, company, serviceProvider }

final shellRoleProvider = NotifierProvider<ShellRoleNotifier, ShellRole>(
  ShellRoleNotifier.new,
);

class ShellRoleNotifier extends Notifier<ShellRole> {
  @override
  /// 默认使用求职者角色，待登录态恢复后再同步为服务端角色。
  ShellRole build() => ShellRole.jobSeeker;

  /// 更新壳层角色，并输出角色切换日志。
  void setRole(ShellRole role) {
    final previousRole = state;
    state = role;
    AppLogger.instance.info(
      'SHELL',
      '壳层角色已切换',
      context: <String, Object?>{'from': previousRole.name, 'to': role.name},
    );
  }
}
