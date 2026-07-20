import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/app_toast.dart';

/// 协议链接定义，统一维护标题国际化 key 与目标地址。
class AgreementLinkDefinition {
  const AgreementLinkDefinition({required this.labelKey, required this.uri});

  final String labelKey;
  final Uri uri;
}

/// 协议链接集合与打开逻辑，供登录页和关于页复用。
abstract final class AgreementLinks {
  static final Uri userTermsUri = Uri.parse('https://yunhezp.vip/app/terms.html');
  static final Uri crossBorderTermsUri = Uri.parse(
    'https://yunhezp.vip/app/cross-terms.html',
  );
  static final Uri privacyPolicyUri = Uri.parse(
    'https://yunhezp.vip/app/privacy-policy.html',
  );

  static final AgreementLinkDefinition userTerms = AgreementLinkDefinition(
    labelKey: '认证.用户服务协议',
    uri: userTermsUri,
  );

  static final AgreementLinkDefinition crossBorderTerms =
      AgreementLinkDefinition(
        labelKey: '认证.个人信息跨境流动用户协议',
        uri: crossBorderTermsUri,
      );

  static final AgreementLinkDefinition privacyPolicy = AgreementLinkDefinition(
    labelKey: '认证.用户隐私政策',
    uri: privacyPolicyUri,
  );

  static final List<AgreementLinkDefinition> aboutAppEntries =
      <AgreementLinkDefinition>[
        userTerms,
        crossBorderTerms,
        privacyPolicy,
      ];

  /// 优先以内嵌 WebView 打开协议，失败时回退系统浏览器，并统一错误提示。
  static Future<bool> open(BuildContext context, Uri uri) async {
    try {
      final bool openedInApp = await launchUrl(
        uri,
        mode: LaunchMode.inAppWebView,
      );
      if (openedInApp) {
        return true;
      }

      final bool opened = await launchUrl(uri);
      if (!opened) {
        await AppToast.show('认证.协议打开失败'.tr());
      }
      return opened;
    } catch (_) {
      await AppToast.show('认证.协议打开失败'.tr());
      return false;
    }
  }
}
