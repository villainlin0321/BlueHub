import 'package:flutter_test/flutter_test.dart';

import '../../lib/shared/network/api_exception.dart';
import '../../patrol_test/fixtures/service_provider_test_cases.dart';
import '../../patrol_test/helpers/service_provider_case_result_helper.dart';
import '../../patrol_test/shared/patrol_test_types.dart';

void main() {
  test('资质管理仅在命中明确前置条件不足信号时记为 BLOCKED', () {
    final result = buildQualificationManagementFailureResult(
      definition: serviceProviderMeCases.first,
      startedAt: DateTime.parse('2026-07-04T10:00:00Z'),
      error: StateError('资料缺失：服务商资质未补全'),
    );

    expect(result.status, PatrolCaseStatus.blocked);
    expect(result.reason, 'qualification_precondition_blocked');
    expect(result.actual, contains('资料缺失'));
  });

  test('资质管理遇到泛化接口异常时记为 FAIL', () {
    final result = buildQualificationManagementFailureResult(
      definition: serviceProviderMeCases.first,
      startedAt: DateTime.parse('2026-07-04T10:00:00Z'),
      error: ApiException.http(statusCode: 500, message: '加载服务商资料失败，请稍后重试'),
    );

    expect(result.status, PatrolCaseStatus.fail);
    expect(result.reason, 'qualification_unexpected_error');
    expect(result.actual, contains('加载服务商资料失败'));
  });
}
