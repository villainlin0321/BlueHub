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
}
