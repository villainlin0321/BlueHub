import 'package:europepass/app/router/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../patrol_test/fixtures/service_provider_expectations.dart';
import '../../lib/shared/ui/test_keys.dart';

void main() {
  test('服务商资质认证流程的各步骤都注册了稳定页面锚点', () {
    final qualificationStepOne =
        serviceProviderRouteMatchers['qualificationCertification'];
    final qualificationStepTwo =
        serviceProviderRouteMatchers['qualificationCertificationStepTwo'];
    final qualificationStepThree =
        serviceProviderRouteMatchers['qualificationCertificationStepThree'];
    final qualificationResult =
        serviceProviderRouteMatchers['qualificationCertificationResult'];

    expect(qualificationStepOne?.routePath, RoutePaths.qualificationCertification);
    expect(
      qualificationStepOne?.readyKey,
      AppTestKeys.pageQualificationCertificationStepOne,
    );

    expect(
      qualificationStepTwo?.routePath,
      RoutePaths.qualificationCertificationStepTwo,
    );
    expect(
      qualificationStepTwo?.readyKey,
      AppTestKeys.pageQualificationCertificationStepTwo,
    );

    expect(
      qualificationStepThree?.routePath,
      RoutePaths.qualificationCertificationStepThree,
    );
    expect(
      qualificationStepThree?.readyKey,
      AppTestKeys.pageQualificationCertificationStepThree,
    );

    expect(qualificationResult?.routePath, RoutePaths.appResult);
    expect(
      qualificationResult?.readyKey,
      AppTestKeys.pageQualificationCertificationResult,
    );
  });
}
