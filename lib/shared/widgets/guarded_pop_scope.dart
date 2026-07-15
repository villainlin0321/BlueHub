import 'package:flutter/material.dart';

/// 为需要禁用系统侧滑返回的页面提供统一能力：
/// 1. 用 `buildGuardedPopScope` 包裹页面，拦截系统返回。
/// 2. 用 `scheduleDirectPop` 在下一帧放行后执行真实返回。
/// 3. 用 `allowDirectPop` 提前放行后续跳转，避免提交成功等场景被误拦截。
mixin GuardedPopScopeMixin<T extends StatefulWidget> on State<T> {
  bool _allowDirectPop = false;

  /// 当前是否允许页面直接执行系统返回。
  @protected
  bool get canDirectPop => _allowDirectPop;

  /// 主动放行当前页面的系统返回，适用于提交成功后即将跳转等场景。
  @protected
  void allowDirectPop() {
    if (_allowDirectPop) {
      return;
    }
    if (!mounted) {
      _allowDirectPop = true;
      return;
    }
    setState(() {
      _allowDirectPop = true;
    });
  }

  /// 先在下一帧放行 `PopScope`，再执行真实返回，避免同一帧 `pop` 被再次拦截。
  @protected
  void scheduleDirectPop({Object? result, VoidCallback? onCannotPop}) {
    if (_allowDirectPop) {
      _popNow(result: result, onCannotPop: onCannotPop);
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _allowDirectPop = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _popNow(result: result, onCannotPop: onCannotPop);
    });
  }

  /// 使用统一 `PopScope` 包裹页面，拦截侧滑与系统返回并回调页面自定义离开逻辑。
  @protected
  Widget buildGuardedPopScope({
    required Widget child,
    required Future<void> Function() onInterceptPop,
  }) {
    return PopScope(
      canPop: canDirectPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop || canDirectPop) {
          return;
        }
        await onInterceptPop();
      },
      child: child,
    );
  }

  /// 统一执行真实 `pop`，并在当前路由不可返回时回退到可选兜底逻辑。
  void _popNow({Object? result, VoidCallback? onCannotPop}) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(result);
      return;
    }
    onCannotPop?.call();
  }
}
