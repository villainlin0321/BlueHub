import 'package:europepass/app/router/app_router.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证启动阶段的路由日志协调逻辑，确保首条进入日志一定代表真实首屏。
void main() {
  test('RouteLogCoordinator 会跳过未完成匹配的初始态，并只记录真实首屏进入', () {
    final coordinator = RouteLogCoordinator();

    expect(coordinator.sync(currentLocation: null), isEmpty);

    final firstResolvedEvents = coordinator.sync(currentLocation: '/home');
    expect(firstResolvedEvents, hasLength(1));
    expect(firstResolvedEvents.single.type, RouteLogTransitionType.enter);
    expect(firstResolvedEvents.single.route, '/home');
    expect(firstResolvedEvents.single.from, isNull);
  });

  test('RouteLogCoordinator 会在后续真实切页时先退出旧页再进入新页', () {
    final coordinator = RouteLogCoordinator();

    coordinator.sync(currentLocation: '/home');
    final routeChangedEvents = coordinator.sync(currentLocation: '/jobs/post');

    expect(routeChangedEvents, hasLength(2));
    expect(routeChangedEvents.first.type, RouteLogTransitionType.exit);
    expect(routeChangedEvents.first.route, '/home');
    expect(routeChangedEvents.first.to, '/jobs/post');
    expect(routeChangedEvents.last.type, RouteLogTransitionType.enter);
    expect(routeChangedEvents.last.route, '/jobs/post');
    expect(routeChangedEvents.last.from, '/home');
  });
}
