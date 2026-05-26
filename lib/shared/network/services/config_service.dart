import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
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
}
