import 'package:bluehub_app/shared/network/api_decoders.dart';

class TagDictVO {
  const TagDictVO({required this.tags});

  final Map<String, List<TagItemVO>> tags;

  factory TagDictVO.fromJson(JsonMap json) {
    return TagDictVO(
      tags: decodeMapValues<List<TagItemVO>>(
        json['tags'] ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'tags': tags};
  }
}

class TagItemVO {
  const TagItemVO({
    required this.tagCode,
    required this.tagNameZh,
    required this.tagNameEn,
    required this.sortOrder,
  });

  final String tagCode;
  final String tagNameZh;
  final String tagNameEn;
  final int sortOrder;

  factory TagItemVO.fromJson(JsonMap json) {
    return TagItemVO(
      tagCode: json['tagCode'] as String? ?? '',
      tagNameZh: json['tagNameZh'] as String? ?? '',
      tagNameEn: json['tagNameEn'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'tagCode': tagCode,
      'tagNameZh': tagNameZh,
      'tagNameEn': tagNameEn,
      'sortOrder': sortOrder,
    };
  }
}
