import 'package:bluehub_app/shared/network/api_decoders.dart';

class TagDictVO {
  const TagDictVO({required this.tags});

  final Map<String, List<TagItemVO>> tags;

  factory TagDictVO.fromJson(JsonMap json) {
    return TagDictVO(
      tags: decodeMapValues<List<TagItemVO>>(
        json['tags'] ?? const <String, dynamic>{},
        (value) => decodeModelList<TagItemVO>(value, TagItemVO.fromJson),
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
      tagCode: readString(json, 'tagCode'),
      tagNameZh: readString(json, 'tagNameZh'),
      tagNameEn: readString(json, 'tagNameEn'),
      sortOrder: readInt(json, 'sortOrder'),
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
