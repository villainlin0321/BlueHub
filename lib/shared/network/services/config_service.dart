import 'dart:ui' show Locale;

import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import '../../../features/config/data/config_models.dart';

/// 标签字典分类枚举。
///
/// `value` 对应后端 `/config/tags` 接口要求的 `category` 查询参数。
/// 业务层调用 `ConfigService.getTags()` 时，优先通过该枚举传参，避免直接散落硬编码字符串。
enum TagCategory {
  /// 亮点标签。
  highlight('highlight'),

  /// 服务标签。
  service('service'),

  /// 要求标签。
  requirement('requirement'),

  /// 福利标签。
  benefit('benefit'),

  /// 语种名称，如英语、日语等。
  languageName('language_name'),

  /// 语言等级，如 N1、雅思 6.5、专八等。
  languageLevel('language_level'),

  /// 语言证书类型。
  languageCert('language_cert'),

  /// 技能证书类型。
  skillCertType('skill_cert_type'),

  /// 学历层级，如高中、大专、本科、硕士等。
  educationLevel('education_level'),

  /// 材料类型，如护照、照片、申请表等。
  materialType('material_type'),

  /// 签证类型，如工作、旅行、技术、护理、留学等。
  visaType('visa_type');

  const TagCategory(this.value);

  final String value;

  /// 根据接口返回的字符串值反查标签分类枚举。
  static TagCategory? fromValue(String? value) {
    for (final category in TagCategory.values) {
      if (category.value == value) {
        return category;
      }
    }
    return null;
  }

  /// 返回当前标签分类对应的接口值。
  @override
  String toString() => value;
}

/// 系统配置相关接口服务。
///
/// 当前主要负责拉取系统标签字典数据，供表单筛选、标签选择器、
/// 发布页配置项和资料页选项等场景复用。
class ConfigService {
  ConfigService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 构建标签查找表，支持通过 code / 中文 / 英文反查标签项。
  static Map<String, TagItemVO> buildTagLookup(Iterable<TagItemVO> tags) {
    final Map<String, TagItemVO> lookup = <String, TagItemVO>{};

    void addKey(String value, TagItemVO item) {
      final String key = _normalizeTagKey(value);
      if (key.isEmpty || lookup.containsKey(key)) {
        return;
      }
      lookup[key] = item;
    }

    for (final TagItemVO item in tags) {
      addKey(item.tagCode, item);
      addKey(item.tagNameZh, item);
      addKey(item.tagNameEn, item);
    }

    return lookup;
  }

  /// 构建按标签分类分组的查找表，便于通过 `TagCategory` 精准解析展示名。
  static Map<TagCategory, Map<String, TagItemVO>> buildTagLookupByCategory(
    Map<String, List<TagItemVO>> groupedTags,
  ) {
    final Map<TagCategory, Map<String, TagItemVO>> lookupByCategory =
        <TagCategory, Map<String, TagItemVO>>{};

    groupedTags.forEach((String key, List<TagItemVO> value) {
      final TagCategory? category = TagCategory.fromValue(key);
      if (category == null || value.isEmpty) {
        return;
      }
      lookupByCategory[category] = buildTagLookup(value);
    });

    return lookupByCategory;
  }

  /// 按当前语言环境解析标签展示文案，找不到映射时回退原始值。
  static String resolveTagLabel({
    required String rawLabel,
    required Map<String, TagItemVO> tagLookup,
    required Locale locale,
  }) {
    final String normalizedLabel = rawLabel.trim();
    if (normalizedLabel.isEmpty) {
      return '';
    }

    final TagItemVO? matched = tagLookup[_normalizeTagKey(normalizedLabel)];
    if (matched == null) {
      return normalizedLabel;
    }

    return resolveLocalizedTagLabel(matched, locale: locale);
  }

  /// 根据标签分类和值解析展示文案，无法匹配时回退原始值。
  static String resolveTagLabelByCategory({
    required String rawLabel,
    required String? rawCategory,
    required Map<TagCategory, Map<String, TagItemVO>> tagLookupByCategory,
    required Locale locale,
  }) {
    final String normalizedLabel = rawLabel.trim();
    if (normalizedLabel.isEmpty) {
      return '';
    }

    final TagCategory? category = TagCategory.fromValue(rawCategory?.trim());
    if (category == null) {
      return normalizedLabel;
    }

    final Map<String, TagItemVO>? tagLookup = tagLookupByCategory[category];
    if (tagLookup == null || tagLookup.isEmpty) {
      return normalizedLabel;
    }

    return resolveTagLabel(
      rawLabel: normalizedLabel,
      tagLookup: tagLookup,
      locale: locale,
    );
  }

  /// 返回标签项在当前语言下应展示的文案。
  static String resolveLocalizedTagLabel(
    TagItemVO item, {
    required Locale locale,
  }) {
    if (isChineseLocale(locale)) {
      final String zh = item.tagNameZh.trim();
      if (zh.isNotEmpty) {
        return zh;
      }
      final String en = item.tagNameEn.trim();
      return en.isNotEmpty ? en : item.tagCode.trim();
    }

    final String en = item.tagNameEn.trim();
    if (en.isNotEmpty) {
      return en;
    }

    final String zh = item.tagNameZh.trim();
    return zh.isNotEmpty ? zh : item.tagCode.trim();
  }

  /// 统一判断是否中文语言环境。
  static bool isChineseLocale(Locale locale) {
    return locale.languageCode.toLowerCase().startsWith('zh');
  }

  /// 获取系统标签字典。
  ///
  /// 不传 `category` 时，返回服务端支持的全部标签分类字典。
  ///
  /// 传入 `category` 时，只返回指定分类的标签集合。
  ///
  /// 常用业务场景如下：
  /// - `TagCategory.languageName` -> `GET /config/tags?category=language_name`
  /// - `TagCategory.languageLevel` -> `GET /config/tags?category=language_level`
  /// - `TagCategory.languageCert` -> `GET /config/tags?category=language_cert`
  /// - `TagCategory.skillCertType` -> `GET /config/tags?category=skill_cert_type`
  /// - `TagCategory.educationLevel` -> `GET /config/tags?category=education_level`
  /// - `TagCategory.materialType` -> `GET /config/tags?category=material_type`
  /// - `TagCategory.visaType` -> `GET /config/tags?category=visa_type`
  ///
  /// 返回值说明：
  /// - 返回 `TagDictVO`
  /// - `TagDictVO.tags` 的 key 为分类字符串，value 为该分类下的标签列表
  ///
  /// 示例：
  /// ```dart
  /// await configService.getTags(category: TagCategory.languageName);
  /// await configService.getTags(category: TagCategory.languageLevel);
  /// ```
  Future<TagDictVO> getTags({TagCategory? category}) async {
    final queryParameters = <String, dynamic>{
      if (category != null) 'category': category.value,
    };
    final response = await _apiClient.get<TagDictVO>(
      '/config/tags',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => TagDictVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  static String _normalizeTagKey(String value) {
    return value.trim().toLowerCase();
  }
}
