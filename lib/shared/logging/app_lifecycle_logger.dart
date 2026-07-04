import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:europepass/shared/logging/app_log_facade.dart';
import 'package:flutter/widgets.dart';

/// 应用生命周期日志组件：把前后台切换等宿主事件接入统一日志门面。
class AppLifecycleLogger extends StatefulWidget {
  const AppLifecycleLogger({super.key, required this.child});

  final Widget child;

  @override
  /// 创建生命周期日志组件状态，负责注册和释放系统观察器。
  State<AppLifecycleLogger> createState() => _AppLifecycleLoggerState();
}

class _AppLifecycleLoggerState extends State<AppLifecycleLogger>
    with WidgetsBindingObserver {
  @override
  /// 注册系统生命周期观察器，并记录挂载完成事件。
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppFlowLog.lifecycle(
      state: 'observer_attached',
      message: '应用生命周期观察器已挂载',
      result: AppLogResult.success,
    );
  }

  @override
  /// 记录生命周期变化，覆盖前后台切换、恢复和暂停等关键状态。
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppFlowLog.lifecycle(
      state: state.name,
      result: _mapLifecycleResult(state),
    );
  }

  @override
  /// 先移除系统观察器，再记录卸载事件，避免释放后继续接收回调。
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppFlowLog.lifecycle(
      state: 'observer_detached',
      message: '应用生命周期观察器已卸载',
      result: AppLogResult.cancel,
    );
    super.dispose();
  }

  @override
  /// 透传原有子树，确保不改变现有 `MaterialApp.router` 结构。
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// 将系统生命周期状态映射为统一日志结果，便于后续检索与统计。
  AppLogResult _mapLifecycleResult(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        return AppLogResult.success;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        return AppLogResult.pending;
      case AppLifecycleState.paused:
        return AppLogResult.skip;
      case AppLifecycleState.detached:
        return AppLogResult.cancel;
    }
  }
}
