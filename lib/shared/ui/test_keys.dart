import 'package:flutter/widgets.dart';

/// 汇总自动化测试依赖的稳定 Key，避免测试直接绑定多语言文案。
class AppTestKeys {
  AppTestKeys._();

  /// 服务商测试登录按钮的稳定定位 Key。
  static const Key loginTestServiceProviderButton = Key(
    'login-test-service-provider',
  );

  /// 服务商首页根节点的稳定定位 Key。
  static const Key pageServiceProviderHome = Key('page-home-service-provider');

  /// 服务商“我的”页根节点的稳定定位 Key。
  static const Key pageServiceProviderMe = Key('page-me-service-provider');

  /// 服务商“我的”页设置按钮的稳定定位 Key。
  static const Key actionServiceProviderMeSettings = Key(
    'action-me-service-provider-settings',
  );

  /// 服务商套餐管理页根节点的稳定定位 Key。
  static const Key pageServiceProviderJobs = Key('page-jobs-service-provider');

  /// 服务商套餐管理页发布按钮的稳定定位 Key。
  static const Key actionServiceProviderJobsPublish = Key(
    'action-jobs-service-provider-publish',
  );

  /// 服务商签证套餐编辑页根节点的稳定定位 Key。
  static const Key pageEditVisaPackage = Key('page-edit-visa-package');

  /// 服务商签证套餐编辑页返回按钮的稳定定位 Key。
  static const Key actionEditVisaPackageBack = Key(
    'action-edit-visa-package-back',
  );

  /// 编辑套餐页套餐总名称输入框的稳定定位 Key。
  static const Key fieldEditVisaPackageName = Key(
    'field-edit-visa-package-name',
  );

  /// 编辑套餐页服务国家选择入口的稳定定位 Key。
  static const Key actionEditVisaPackageCountry = Key(
    'action-edit-visa-package-country',
  );

  /// 编辑套餐页签证类型选择入口的稳定定位 Key。
  static const Key actionEditVisaPackageVisaType = Key(
    'action-edit-visa-package-visa-type',
  );

  /// 编辑套餐页保存草稿按钮的稳定定位 Key。
  static const Key actionEditVisaPackageSaveDraft = Key(
    'action-edit-visa-package-save-draft',
  );

  /// 编辑套餐页立即发布按钮的稳定定位 Key。
  static const Key actionEditVisaPackagePublish = Key(
    'action-edit-visa-package-publish',
  );

  /// 服务商签证页根节点的稳定定位 Key。
  static const Key pageServiceProviderVisa = Key('page-visa-service-provider');

  /// 服务商签证页国家筛选按钮的稳定定位 Key。
  static const Key actionServiceProviderVisaCountryFilter = Key(
    'action-visa-service-provider-country-filter',
  );

  /// 服务商签证页状态筛选按钮的稳定定位 Key。
  static const Key actionServiceProviderVisaStatusFilter = Key(
    'action-visa-service-provider-status-filter',
  );

  /// 服务商资质认证第一步页面根节点的稳定定位 Key。
  static const Key pageQualificationCertificationStepOne = Key(
    'page-qualification-certification-step-one',
  );

  /// 服务商资质认证第二步页面根节点的稳定定位 Key。
  static const Key pageQualificationCertificationStepTwo = Key(
    'page-qualification-certification-step-two',
  );

  /// 服务商资质认证第三步页面根节点的稳定定位 Key。
  static const Key pageQualificationCertificationStepThree = Key(
    'page-qualification-certification-step-three',
  );

  /// 服务商资质认证提交结果页根节点的稳定定位 Key。
  static const Key pageQualificationCertificationResult = Key(
    'page-qualification-certification-result',
  );

  /// 服务商资质认证企业名称输入框的稳定定位 Key。
  static const Key fieldQualificationCompanyName = Key(
    'field-qualification-company-name',
  );

  /// 服务商资质认证统一社会信用代码输入框的稳定定位 Key。
  static const Key fieldQualificationCreditCode = Key(
    'field-qualification-credit-code',
  );

  /// 服务商资质认证法人姓名输入框的稳定定位 Key。
  static const Key fieldQualificationLegalPerson = Key(
    'field-qualification-legal-person',
  );

  /// 服务商资质认证官方联系人输入框的稳定定位 Key。
  static const Key fieldQualificationContactPerson = Key(
    'field-qualification-contact-person',
  );

  /// 服务商资质认证联系电话输入框的稳定定位 Key。
  static const Key fieldQualificationContactPhone = Key(
    'field-qualification-contact-phone',
  );

  /// 服务商资质认证邮箱输入框的稳定定位 Key。
  static const Key fieldQualificationContactEmail = Key(
    'field-qualification-contact-email',
  );

  /// 服务商资质认证公司官网输入框的稳定定位 Key。
  static const Key fieldQualificationWebsite = Key(
    'field-qualification-website',
  );

  /// 服务商资质认证身份证国徽面上传入口的稳定定位 Key。
  static const Key actionQualificationIdCardEmblemUpload = Key(
    'action-qualification-id-card-emblem-upload',
  );

  /// 服务商资质认证身份证人像面上传入口的稳定定位 Key。
  static const Key actionQualificationIdCardPortraitUpload = Key(
    'action-qualification-id-card-portrait-upload',
  );

  /// 服务商资质认证第一步“下一步”按钮的稳定定位 Key。
  static const Key actionQualificationStepOneNext = Key(
    'action-qualification-step-one-next',
  );

  /// 服务商资质认证营业执照上传入口的稳定定位 Key。
  static const Key actionQualificationBusinessLicenseUpload = Key(
    'action-qualification-business-license-upload',
  );

  /// 服务商资质认证特许许可上传入口的稳定定位 Key。
  static const Key actionQualificationSpecialPermitUpload = Key(
    'action-qualification-special-permit-upload',
  );

  /// 服务商资质认证第二步“下一步”按钮的稳定定位 Key。
  static const Key actionQualificationStepTwoNext = Key(
    'action-qualification-step-two-next',
  );

  /// 服务商资质认证服务国家选择入口的稳定定位 Key。
  static const Key actionQualificationServiceCountrySelect = Key(
    'action-qualification-service-country-select',
  );

  /// 服务商资质认证从业年限输入框的稳定定位 Key。
  static const Key fieldQualificationYearsOfService = Key(
    'field-qualification-years-of-service',
  );

  /// 服务商资质认证提交审核按钮的稳定定位 Key。
  static const Key actionQualificationSubmit = Key(
    'action-qualification-submit',
  );

  /// 返回服务商套餐管理页指定状态 Tab 的稳定定位 Key。
  static Key tabServiceProviderJobs(String tabStatus) {
    return Key('tab-jobs-service-provider-$tabStatus');
  }

  /// 返回服务商套餐管理页指定状态内容面板的稳定定位 Key。
  static Key sectionServiceProviderJobsPanel(String tabStatus) {
    return Key('section-jobs-service-provider-panel-$tabStatus');
  }

  /// 返回服务商套餐管理页指定套餐编辑按钮的稳定定位 Key。
  static Key actionServiceProviderJobsEdit(String tabStatus, int packageId) {
    return Key('action-jobs-service-provider-edit-$tabStatus-$packageId');
  }

  /// 返回服务商套餐管理页指定套餐删除按钮的稳定定位 Key。
  static Key actionServiceProviderJobsDelete(String tabStatus, int packageId) {
    return Key('action-jobs-service-provider-delete-$tabStatus-$packageId');
  }

  /// 返回服务商套餐管理页指定套餐上下架按钮的稳定定位 Key。
  static Key actionServiceProviderJobsStatusToggle(
    String tabStatus,
    int packageId,
  ) {
    return Key(
      'action-jobs-service-provider-status-toggle-$tabStatus-$packageId',
    );
  }

  /// 返回服务商签证页指定订单卡片的稳定定位 Key。
  static Key cardServiceProviderVisaOrder(int orderId) {
    return Key('card-visa-service-provider-order-$orderId');
  }

  /// 返回服务商签证页指定订单“联系客户”按钮的稳定定位 Key。
  static Key actionServiceProviderVisaOrderContact(int orderId) {
    return Key('action-visa-service-provider-order-contact-$orderId');
  }

  /// 返回服务商签证页指定订单“处理订单”按钮的稳定定位 Key。
  static Key actionServiceProviderVisaOrderProcess(int orderId) {
    return Key('action-visa-service-provider-order-process-$orderId');
  }
}
