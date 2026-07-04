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

  /// 返回服务商套餐管理页指定状态 Tab 的稳定定位 Key。
  static Key tabServiceProviderJobs(String tabStatus) {
    return Key('tab-jobs-service-provider-$tabStatus');
  }

  /// 返回服务商套餐管理页指定状态内容面板的稳定定位 Key。
  static Key sectionServiceProviderJobsPanel(String tabStatus) {
    return Key('section-jobs-service-provider-panel-$tabStatus');
  }

  /// 返回服务商套餐管理页列表首项编辑按钮的稳定定位 Key。
  static Key actionServiceProviderJobsEdit(String tabStatus, int index) {
    return Key('action-jobs-service-provider-edit-$tabStatus-$index');
  }

  /// 返回服务商套餐管理页列表首项删除按钮的稳定定位 Key。
  static Key actionServiceProviderJobsDelete(String tabStatus, int index) {
    return Key('action-jobs-service-provider-delete-$tabStatus-$index');
  }

  /// 返回服务商套餐管理页列表首项上下架按钮的稳定定位 Key。
  static Key actionServiceProviderJobsStatusToggle(
    String tabStatus,
    int index,
  ) {
    return Key('action-jobs-service-provider-status-toggle-$tabStatus-$index');
  }
}
