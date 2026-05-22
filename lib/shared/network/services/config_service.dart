import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import '../../../features/config/data/config_models.dart';

enum TagCategory {
  highlight('highlight'),
  service('service'),
  requirement('requirement'),
  benefit('benefit');

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

class ConfigService {
  ConfigService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取系统标签字典。
  ///
  /// 传入 `category` 时只返回指定分类的标签集合。
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
