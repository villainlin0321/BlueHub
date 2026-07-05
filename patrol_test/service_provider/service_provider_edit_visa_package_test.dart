import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('编辑套餐 - 套餐名称输入与保存草稿应可执行', ($) async {
    await bootstrapPatrolApp($);
    await ensureServiceProviderAuthenticated(
      $,
      ServiceProviderTestAccount.fromEnvironment(),
    );

    await $('套餐').tap();
    await $(find.byKey(AppTestKeys.actionServiceProviderJobsPublish)).tap();
    await waitForPageReady($, page: 'editVisaPackage');

    await $(find.byKey(AppTestKeys.fieldEditVisaPackageName)).enterText(
      'Patrol 测试套餐',
    );
    await $(find.byKey(AppTestKeys.actionEditVisaPackageSaveDraft)).tap();

    await $('请选择服务国家').waitUntilVisible();
  });
}
