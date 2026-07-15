import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('服务商资质认证闭环所需的关键输入与操作锚点已定义', () {
    expect(
      AppTestKeys.fieldQualificationCompanyName,
      const Key('field-qualification-company-name'),
    );
    expect(
      AppTestKeys.fieldQualificationCreditCode,
      const Key('field-qualification-credit-code'),
    );
    expect(
      AppTestKeys.fieldQualificationLegalPerson,
      const Key('field-qualification-legal-person'),
    );
    expect(
      AppTestKeys.actionQualificationIdCardEmblemUpload,
      const Key('action-qualification-id-card-emblem-upload'),
    );
    expect(
      AppTestKeys.actionQualificationIdCardPortraitUpload,
      const Key('action-qualification-id-card-portrait-upload'),
    );
    expect(
      AppTestKeys.actionQualificationStepOneNext,
      const Key('action-qualification-step-one-next'),
    );
    expect(
      AppTestKeys.actionQualificationBusinessLicenseUpload,
      const Key('action-qualification-business-license-upload'),
    );
    expect(
      AppTestKeys.actionQualificationStepTwoNext,
      const Key('action-qualification-step-two-next'),
    );
    expect(
      AppTestKeys.actionQualificationServiceCountrySelect,
      const Key('action-qualification-service-country-select'),
    );
    expect(
      AppTestKeys.fieldQualificationYearsOfService,
      const Key('field-qualification-years-of-service'),
    );
    expect(
      AppTestKeys.actionQualificationSubmit,
      const Key('action-qualification-submit'),
    );
  });
}
