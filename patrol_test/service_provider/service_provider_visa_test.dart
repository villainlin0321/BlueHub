import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('服务商签证页 - 国家与状态筛选应可打开', ($) async {
    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );

    await $('订单').tap();
    await expectRouteReady(
      $,
      routePath: RoutePaths.visa,
      fallbackFinder: find.byKey(AppTestKeys.pageServiceProviderVisa),
    );

    await $(find.byKey(AppTestKeys.actionServiceProviderVisaCountryFilter)).tap();
    await $('选择国家').waitUntilVisible();

    await $.native.pressBack();

    await $(find.byKey(AppTestKeys.actionServiceProviderVisaStatusFilter)).tap();
    await $('选择订单状态').waitUntilVisible();
  });
}
