import 'dart:async';

import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../fixtures/service_provider_expectations.dart';
import '../fixtures/service_provider_test_account.dart';
import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_route_matcher.dart';
import '../helpers/patrol_wait_helper.dart';

void main() {
  patrolTest('服务商我的 - 资质认证三步表单、真实上传与提交闭环', ($) async {
    await _openServiceProviderMePage($);
    await _runQualificationCertificationFlow($);
  });

  patrolTest('服务商我的 - 订单管理入口可达', ($) async {
    await _openServiceProviderMePage($);
    await $('订单管理').tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['orderManagement']!);
  });

  patrolTest('服务商我的 - 财务结算入口可达', ($) async {
    await _openServiceProviderMePage($);
    await $('财务结算').tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['financeSettlement']!);
  });

  patrolTest('服务商我的 - 设置入口可达', ($) async {
    await _openServiceProviderMePage($);
    await $(find.byKey(AppTestKeys.actionServiceProviderMeSettings)).tap();
    await _waitForMatcher($, serviceProviderRouteMatchers['settings']!);
  });
}

/// 打开并稳定停留在服务商“我的”页，供后续独立用例复用。
Future<void> _openServiceProviderMePage(PatrolIntegrationTester $) async {
  await bootstrapPatrolApp($);
  await ensureServiceProviderAuthenticated(
    $,
    ServiceProviderTestAccount.fromEnvironment(),
  );

  await $('我的').tap();
  await waitForPageReady($, page: 'serviceProviderMe');
}

/// 执行资质认证的三步真实闭环：填写、上传、选择国家并提交。
Future<void> _runQualificationCertificationFlow(PatrolIntegrationTester $) async {
  await $('资质管理').tap();
  await waitForPageReady($, page: 'qualificationCertificationStepOne');

  await $(find.byKey(AppTestKeys.fieldQualificationCompanyName)).enterText(
    'Patrol 服务商有限公司',
  );
  await $(find.byKey(AppTestKeys.fieldQualificationCreditCode)).enterText(
    '91310000PATROL001',
  );
  await $(find.byKey(AppTestKeys.fieldQualificationLegalPerson)).enterText('张三');
  await $(find.byKey(AppTestKeys.fieldQualificationContactPerson)).enterText(
    '李四',
  );
  await $(find.byKey(AppTestKeys.fieldQualificationContactPhone)).enterText(
    '13800138000',
  );
  await $(find.byKey(AppTestKeys.fieldQualificationContactEmail)).enterText(
    'patrol@example.com',
  );
  await $(find.byKey(AppTestKeys.fieldQualificationWebsite)).enterText(
    'https://example.com',
  );

  await _uploadImageFromGallery(
    $,
    uploadActionKey: AppTestKeys.actionQualificationIdCardEmblemUpload,
    pageAliasAfterUpload: 'qualificationCertificationStepOne',
  );
  await _uploadImageFromGallery(
    $,
    uploadActionKey: AppTestKeys.actionQualificationIdCardPortraitUpload,
    pageAliasAfterUpload: 'qualificationCertificationStepOne',
  );

  await $(find.byKey(AppTestKeys.actionQualificationStepOneNext)).tap();
  await waitForPageReady($, page: 'qualificationCertificationStepTwo');

  await _uploadImageFromGallery(
    $,
    uploadActionKey: AppTestKeys.actionQualificationBusinessLicenseUpload,
    pageAliasAfterUpload: 'qualificationCertificationStepTwo',
  );
  await _uploadImageFromGallery(
    $,
    uploadActionKey: AppTestKeys.actionQualificationSpecialPermitUpload,
    pageAliasAfterUpload: 'qualificationCertificationStepTwo',
  );

  await $(find.byKey(AppTestKeys.actionQualificationStepTwoNext)).tap();
  await waitForPageReady($, page: 'qualificationCertificationStepThree');

  await $(find.byKey(AppTestKeys.actionQualificationServiceCountrySelect)).tap();
  await _selectFirstCountryFromBottomSheet($, title: '期望国家地区');
  await $(find.byKey(AppTestKeys.fieldQualificationYearsOfService)).enterText(
    '5',
  );

  await $(find.byKey(AppTestKeys.actionQualificationSubmit)).tap();
  await waitForPageReady($, page: 'qualificationCertificationResult');
}

/// 统一走应用内图片来源弹层与 Patrol 原生图库选择，完成一次真实上传。
Future<void> _uploadImageFromGallery(
  PatrolIntegrationTester $, {
  required Key uploadActionKey,
  required String pageAliasAfterUpload,
}) async {
  await $(find.byKey(uploadActionKey)).tap();
  await $('相册').tap();
  await $.native.pickImageFromGallery(index: 0);
  await waitForPageReady($, page: pageAliasAfterUpload);
  await _waitUntilUploadSettled($);
}

/// 等待上传中的进度指示器消失，确保图片上传动作已经完成。
Future<void> _waitUntilUploadSettled(PatrolIntegrationTester $) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    await $.tester.pump(const Duration(milliseconds: 200));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      return;
    }
  }
  throw TimeoutException('资质图片上传超时，20 秒内未完成');
}

/// 从国家选择底部弹层中选择第一项有效国家，并确认返回页面。
Future<void> _selectFirstCountryFromBottomSheet(
  PatrolIntegrationTester $, {
  required String title,
}) async {
  await $(title).waitUntilVisible();
  await $.tester.pump();

  final labels = $.tester
      .widgetList<Text>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Text),
        ),
      )
      .map((widget) => widget.data?.trim() ?? '')
      .where(
        (label) =>
            label.isNotEmpty && label != title && label != '确定' && label != '关闭',
      )
      .toList(growable: false);

  if (labels.isEmpty) {
    throw StateError('暂无可选国家');
  }

  await $(labels.first).tap();
  await $('确定').tap();
}

/// 按统一 matcher 定义等待路由就绪，优先复用 Task2 已完成的等待 helper。
Future<void> _waitForMatcher(
  PatrolIntegrationTester $,
  PatrolRouteMatcher matcher,
) async {
  await expectRouteReady(
    $,
    routePath: matcher.routePath,
    fallbackFinder: matcher.readyKey != null
        ? find.byKey(matcher.readyKey!)
        : find.text(matcher.fallbackText!),
  );
}
