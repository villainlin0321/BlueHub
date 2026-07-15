import 'package:dio/dio.dart';

import '../../localization/app_language_store.dart';

class LanguageInterceptor extends Interceptor {
  LanguageInterceptor(this._languageStore);

  static const String _headerKey = 'Accept-Language';

  final AppLanguageStore _languageStore;

  @override
  /// 在请求发出前补齐当前语言，让服务端文案与客户端语言切换保持一致。
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final currentValue = options.headers[_headerKey]?.toString().trim() ?? '';
    if (currentValue.isEmpty) {
      options.headers[_headerKey] = _languageStore.currentLanguageCode;
    }
    handler.next(options);
  }
}
