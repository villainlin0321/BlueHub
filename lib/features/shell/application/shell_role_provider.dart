import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ShellRole { jobSeeker, company, serviceProvider }

final shellRoleProvider = NotifierProvider<ShellRoleNotifier, ShellRole>(
  ShellRoleNotifier.new,
);

class ShellRoleNotifier extends Notifier<ShellRole> {
  @override
  ShellRole build() => ShellRole.jobSeeker;

  void setRole(ShellRole role) {
    state = role;
  }
}
