/// 描述服务商 Patrol 测试在手工兜底登录时所需的账号信息。
class ServiceProviderTestAccount {
  /// 创建服务商测试账号对象。
  const ServiceProviderTestAccount({
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  /// 从环境变量读取服务商测试账号，避免把真实测试数据写进仓库。
  static ServiceProviderTestAccount fromEnvironment() {
    return ServiceProviderTestAccount(
      email: const String.fromEnvironment(
        'PATROL_SERVICE_PROVIDER_EMAIL',
        defaultValue: '',
      ),
      code: const String.fromEnvironment(
        'PATROL_SERVICE_PROVIDER_CODE',
        defaultValue: '',
      ),
    );
  }

  /// 标记当前账号信息是否完整，便于测试在缺少兜底数据时尽早报错。
  bool get isValid => email.trim().isNotEmpty && code.trim().isNotEmpty;
}
