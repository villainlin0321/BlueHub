class PaymentChannelConfig {
  const PaymentChannelConfig({
    required this.weChatAppId,
    required this.weChatUniversalLinkHost,
    required this.aliPayUrlScheme,
  });

  final String weChatAppId;
  final String weChatUniversalLinkHost;
  final String aliPayUrlScheme;

  static PaymentChannelConfig fromEnvironment() {
    const weChatAppId = String.fromEnvironment(
      'WECHAT_APP_ID',
      defaultValue: '',
    );
    const weChatUniversalLinkHost = String.fromEnvironment(
      'WECHAT_UNIVERSAL_LINK',
      defaultValue: '',
    );
    const aliPayUrlScheme = String.fromEnvironment(
      'ALIPAY_URL_SCHEME',
      defaultValue: 'com.europepass.europepass.alipay',
    );
    return PaymentChannelConfig(
      weChatAppId: weChatAppId.trim(),
      weChatUniversalLinkHost: _normalizeUniversalLinkHost(
        weChatUniversalLinkHost,
      ),
      aliPayUrlScheme: aliPayUrlScheme.trim(),
    );
  }

  bool get hasWeChatConfig =>
      weChatAppId.isNotEmpty && weChatUniversalLinkHost.isNotEmpty;

  bool get hasAliPayConfig => aliPayUrlScheme.isNotEmpty;

  String? get weChatUniversalLink {
    if (weChatUniversalLinkHost.isEmpty) {
      return null;
    }
    return 'https://$weChatUniversalLinkHost/';
  }

  static String _normalizeUniversalLinkHost(String raw) {
    String value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    value = value.replaceFirst(RegExp(r'^https?://'), '');
    value = value.replaceFirst(RegExp(r'/+$'), '');
    return value;
  }
}
