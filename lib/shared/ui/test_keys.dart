import 'package:flutter/widgets.dart';

/// 汇总自动化测试依赖的稳定 Key，避免测试直接绑定多语言文案。
class AppTestKeys {
  AppTestKeys._();

  /// 服务商测试登录按钮的稳定定位 Key。
  static const Key loginTestServiceProviderButton = Key(
    'login-test-service-provider',
  );

  /// 求职者测试登录按钮的稳定定位 Key。
  static const Key loginTestJobSeekerButton = Key(
    'login-test-job-seeker',
  );

  /// 求职者首页根节点的稳定定位 Key。
  static const Key pageJobSeekerHome = Key('page-home-job-seeker');

  /// 求职者“我的”页根节点的稳定定位 Key。
  static const Key pageJobSeekerMe = Key('page-me-job-seeker');

  /// 求职者实名认证页根节点的稳定定位 Key。
  static const Key pageJobSeekerRealNameVerification = Key(
    'page-real-name-job-seeker',
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

  /// 自我评价页根节点的稳定定位 Key。
  static const Key pageSelfEvaluation = Key('page-self-evaluation');

  /// 自我评价输入框的稳定定位 Key。
  static const Key fieldSelfEvaluationInput = Key(
    'field-self-evaluation-input',
  );

  /// 自我评价保存按钮的稳定定位 Key。
  static const Key actionSelfEvaluationSave = Key(
    'action-self-evaluation-save',
  );

  /// 自我评价完成按钮的稳定定位 Key。
  static const Key actionSelfEvaluationDone = Key(
    'action-self-evaluation-done',
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
