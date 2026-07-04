import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../patrol_test/helpers/patrol_route_matcher.dart';

void main() {
  test('路由匹配器会保存 routePath、readyKey 与 fallbackText', () {
    const routeMatcher = PatrolRouteMatcher(
      routePath: '/order/management',
      readyKey: Key('page-order-management'),
      fallbackText: '订单管理',
    );

    expect(routeMatcher.routePath, '/order/management');
    expect(routeMatcher.readyKey, const Key('page-order-management'));
    expect(routeMatcher.fallbackText, '订单管理');
  });
}
