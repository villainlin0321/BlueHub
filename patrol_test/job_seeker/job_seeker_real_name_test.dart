import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/app_bootstrap.dart';
import '../helpers/auth_test_helper.dart';
import '../helpers/patrol_wait_helper.dart';

/// 真实链路下的求职者实名认证 Patrol 验收。
void main() {
  patrolTest('求职者实名认证 - 提交成功后返回我的页并展示已实名状态', ($) async {
    await bootstrapPatrolApp($);
    await ensureJobSeekerAuthenticated($);

    await $('我的').tap();
    await waitForPageReady($, page: 'jobSeekerMe');

    // 按当前交互约定：左侧资料区进入实名认证流程。
    await $(find.byKey(const ValueKey<String>('job_seeker_profile_info_hotspot'))).tap();
    await waitForPageReady($, page: 'jobSeekerRealNameVerification');

    await $(find.byKey(const Key('real-name-input'))).enterText('张三');
    await $(find.byKey(const Key('id-card-input'))).enterText('110101199003047777');

    await _selectPatrolRealImage(
      $,
      uploadCardKey: const Key('id-card-emblem-upload'),
    );
    await _selectPatrolRealImage(
      $,
      uploadCardKey: const Key('id-card-portrait-upload'),
    );

    await $(find.byKey(const Key('real-name-submit-button'))).tap();
    await $.pumpAndSettle();

    await $(find.byKey(AppTestKeys.pageJobSeekerMe)).waitUntilVisible();
    // 提交成功后资料刷新与页面重建存在异步窗口，需等待已实名文案真正渲染完成。
    await $('已完成实名认证').waitUntilVisible();
    expect(find.text('已完成实名认证'), findsOneWidget);
  });
}

/// 点击上传卡片，由测试开关直接回填本地真实图片文件。
Future<void> _selectPatrolRealImage(
  PatrolIntegrationTester $, {
  required Key uploadCardKey,
}) async {
  await $(find.byKey(uploadCardKey)).tap();
  await $.pumpAndSettle();
}
