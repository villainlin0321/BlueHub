import 'dart:convert';
import 'dart:io';

import 'package:europepass/patrol_test/helpers/patrol_reporter.dart';
import 'package:europepass/patrol_test/helpers/patrol_screenshot_helper.dart';
import 'package:europepass/patrol_test/shared/patrol_test_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PatrolReporter 会输出 markdown 与 json 摘要', () async {
    final reporter = PatrolReporter.memory();

    await reporter.record(
      PatrolCaseResult(
        module: 'service_provider',
        page: 'home',
        feature: 'publish_package',
        description: '点击发布套餐',
        precondition: '已进入服务商首页',
        expected: '进入发布套餐页',
        actual: '成功进入发布套餐页',
        status: PatrolCaseStatus.pass,
        reason: 'ok',
        startedAt: DateTime.parse('2026-07-04T10:00:00Z'),
        endedAt: DateTime.parse('2026-07-04T10:00:02Z'),
      ),
    );

    final outputs = await reporter.flushToMemory();
    final markdown = outputs.markdown;
    final json = jsonDecode(outputs.json) as Map<String, Object?>;

    expect(markdown, contains('服务商首页'));
    expect(markdown, contains('发布套餐 | PASS | 成功进入发布套餐页'));
    expect((json['results'] as List<Object?>).length, 1);
    expect((json['summary'] as Map<String, Object?>)['pass'], 1);
  });

  test('PatrolReporter flush 会落盘 markdown 与 json 文件', () async {
    final directory = await Directory.systemTemp.createTemp(
      'patrol-report-files',
    );
    final reporter = PatrolReporter(reportDirectory: directory);

    await reporter.record(
      PatrolCaseResult(
        module: 'service_provider',
        page: 'jobs',
        feature: 'order_management',
        description: '点击订单处理',
        precondition: '已进入服务商套餐管理',
        expected: '进入订单管理页',
        actual: '未进入订单管理页',
        status: PatrolCaseStatus.fail,
        reason: 'route_mismatch',
        startedAt: DateTime.parse('2026-07-04T10:00:00Z'),
        endedAt: DateTime.parse('2026-07-04T10:00:03Z'),
      ),
    );

    await reporter.flush();

    final markdownFile = File('${directory.path}/service_provider_report.md');
    final jsonFile = File('${directory.path}/service_provider_report.json');

    expect(await markdownFile.exists(), isTrue);
    expect(await jsonFile.exists(), isTrue);
    expect(await markdownFile.readAsString(), contains('服务商套餐管理'));
    expect(await jsonFile.readAsString(), contains('"fail":1'));
  });

  test('buildPatrolScreenshotFileName 会生成稳定文件名', () {
    final fileName = buildPatrolScreenshotFileName(
      page: 'visa',
      feature: 'contact-customer',
      now: DateTime.parse('2026-07-04T10:00:02Z'),
    );

    expect(fileName, '2026-07-04T10-00-02.000Z_visa_contact_customer.png');
  });
}
