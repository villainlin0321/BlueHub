import 'dart:ui' show Locale;

import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import 'package:europepass/shared/network/models/dictionary_models.dart';
import 'package:europepass/shared/network/page_result.dart';

class CountryService {
  CountryService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 将国家列表转换为当前语言环境下的 `国家码 -> 展示文案` 映射。
  static Map<String, String> buildLocalizedCountryLabelMap(
    Iterable<CountryVO> countries, {
    required Locale locale,
  }) {
    final Map<String, String> labelMap = <String, String>{};

    for (final CountryVO item in countries) {
      final String key = _normalizeCountryCode(item.countryCode);
      if (key.isEmpty || labelMap.containsKey(key)) {
        continue;
      }
      labelMap[key] = resolveLocalizedCountryLabel(item, locale: locale);
    }

    return labelMap;
  }

  /// 根据当前语言环境解析国家名称，缺失时按中英文和国家码顺序回退。
  static String resolveLocalizedCountryLabel(
    CountryVO item, {
    required Locale locale,
  }) {
    if (_isChineseLocale(locale)) {
      final String zh = item.nameZh.trim();
      if (zh.isNotEmpty) {
        return zh;
      }
      final String en = item.nameEn.trim();
      return en.isNotEmpty ? en : _normalizeCountryCode(item.countryCode);
    }

    final String en = item.nameEn.trim();
    if (en.isNotEmpty) {
      return en;
    }
    final String zh = item.nameZh.trim();
    return zh.isNotEmpty ? zh : _normalizeCountryCode(item.countryCode);
  }

  /// 搜索国家/地区列表，未传关键字时返回按权重排序的启用国家。
  Future<PageResult<CountryVO>> searchCountries({
    String? keyword,
    int? page,
    int? pageSize,
  }) async {
    final queryParameters = <String, dynamic>{
      if (keyword != null) 'keyword': keyword,
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<CountryVO>>(
      '/countries',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<CountryVO>.fromJson(
        asJsonMap(data),
        fromJson: CountryVO.fromJson,
      ),
    );
    return response;
  }

  static String _normalizeCountryCode(String value) {
    return value.trim().toUpperCase();
  }

  static bool _isChineseLocale(Locale locale) {
    return locale.languageCode.toLowerCase().startsWith('zh');
  }
}
