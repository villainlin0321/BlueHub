/// 路由追踪器：维护当前路由、上一跳路由以及一份轻量路由栈快照。
class AppRouteTracker {
  AppRouteTracker();

  /// 全局单例，供路由日志、HTTP 日志和业务日志统一复用当前路由上下文。
  static final AppRouteTracker instance = AppRouteTracker();

  final List<String> _routeStack = <String>[];

  String? _currentRoute;
  String? _previousRoute;

  /// 当前可用于关联日志的页面路由。
  String? get currentRoute => _currentRoute;

  /// 最近一次跳转前所在的页面路由。
  String? get previousRoute => _previousRoute;

  /// 返回当前维护的轻量路由栈快照，便于排查跳转链路。
  List<String> get routeStack => List<String>.unmodifiable(_routeStack);

  /// 记录一次前进导航，并把新页面设置为当前路由。
  void didPush(String route) {
    _track(route);
  }

  /// 记录一次返回导航，并把返回后的页面设置为当前路由。
  void didPop(String route) {
    _track(route);
  }

  /// 记录一次替换导航，并用新页面覆盖当前路由。
  void didReplace(String route) {
    _track(route, replaceCurrent: true);
  }

  /// 按当前路由结果做一次幂等同步，适合给 `go_router` 监听器复用。
  void track(String route) {
    _track(route);
  }

  /// 清空已记录的路由状态，便于测试或重新初始化时重置上下文。
  void reset() {
    _routeStack.clear();
    _currentRoute = null;
    _previousRoute = null;
  }

  /// 用统一规则更新路由状态，并尽量从新旧页面关系推断 push/pop 行为。
  void _track(String route, {bool replaceCurrent = false}) {
    final normalizedRoute = _normalizeRoute(route);
    if (normalizedRoute == null) {
      return;
    }

    if (_currentRoute == normalizedRoute && !replaceCurrent) {
      return;
    }

    final previousCurrentRoute = _currentRoute;

    if (_routeStack.isEmpty) {
      _routeStack.add(normalizedRoute);
    } else if (replaceCurrent) {
      _routeStack[_routeStack.length - 1] = normalizedRoute;
    } else if (_routeStack.length >= 2 &&
        _routeStack[_routeStack.length - 2] == normalizedRoute) {
      // 关键逻辑：当目标页恰好是栈内上一页时，视为一次返回导航。
      _routeStack.removeLast();
    } else if (_routeStack.last != normalizedRoute) {
      _routeStack.add(normalizedRoute);
    }

    _currentRoute = normalizedRoute;
    _previousRoute = previousCurrentRoute;
  }

  /// 统一裁剪空白并过滤非法路由值，避免日志上下文被空字符串污染。
  String? _normalizeRoute(String route) {
    final normalizedRoute = route.trim();
    if (normalizedRoute.isEmpty) {
      return null;
    }
    return normalizedRoute;
  }
}
