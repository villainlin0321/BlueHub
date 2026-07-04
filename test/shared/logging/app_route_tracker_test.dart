import 'package:europepass/shared/logging/app_route_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证路由追踪器会维护当前路由与上一跳路由。
void main() {
  test('AppRouteTracker 会记录当前路由并支持前后页面切换', () {
    final tracker = AppRouteTracker();

    tracker.didPush('/login');
    expect(tracker.currentRoute, '/login');

    tracker.didPush('/jobs/post');
    expect(tracker.previousRoute, '/login');
    expect(tracker.currentRoute, '/jobs/post');

    tracker.didPop('/login');
    expect(tracker.currentRoute, '/login');
  });
}
