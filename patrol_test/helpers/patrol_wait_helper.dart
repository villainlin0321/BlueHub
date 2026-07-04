import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'patrol_route_matcher.dart';

const Map<String, PatrolRouteMatcher> _pageMatchers =
    <String, PatrolRouteMatcher>{
      'home': PatrolRouteMatcher(
        routePath: RoutePaths.home,
        readyKey: AppTestKeys.pageServiceProviderHome,
      ),
      'serviceProviderHome': PatrolRouteMatcher(
        routePath: RoutePaths.home,
        readyKey: AppTestKeys.pageServiceProviderHome,
      ),
    };

/// 按页面别名等待目标页面完成渲染，避免在测试里直接写固定休眠。
Future<void> waitForPageReady(
  PatrolIntegrationTester $, {
  required String page,
}) async {
  final matcher = _pageMatchers[page];
  if (matcher == null) {
    throw ArgumentError.value(page, 'page', '未注册的 Patrol 页面别名');
  }
  await _waitByMatcher($, matcher);
}

/// 等待指定路由对应的关键元素出现，优先使用稳定 Key，失败时退回兜底 Finder。
Future<void> expectRouteReady(
  PatrolIntegrationTester $, {
  required String routePath,
  required Finder fallbackFinder,
}) async {
  PatrolRouteMatcher? matcher;
  for (final item in _pageMatchers.values) {
    if (item.routePath == routePath) {
      matcher = item;
      break;
    }
  }

  if (matcher?.readyKey != null) {
    await $(find.byKey(matcher!.readyKey!)).waitUntilVisible();
    return;
  }
  await $(fallbackFinder).waitUntilVisible();
}

/// 按 matcher 定义的优先级等待页面锚点出现。
Future<void> _waitByMatcher(
  PatrolIntegrationTester $,
  PatrolRouteMatcher matcher,
) async {
  if (matcher.readyKey != null) {
    await $(find.byKey(matcher.readyKey!)).waitUntilVisible();
    return;
  }
  if (matcher.fallbackText != null) {
    await $(matcher.fallbackText!).waitUntilVisible();
    return;
  }
  throw ArgumentError('matcher.readyKey 和 matcher.fallbackText 不能同时为空');
}
