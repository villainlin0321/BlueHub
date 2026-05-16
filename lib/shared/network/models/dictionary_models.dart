import 'package:bluehub_app/shared/network/api_decoders.dart';

class CountryVO {
  const CountryVO({
    required this.countryCode,
    required this.nameZh,
    required this.nameEn,
  });

  final String countryCode;
  final String nameZh;
  final String nameEn;

  factory CountryVO.fromJson(JsonMap json) {
    return CountryVO(
      countryCode: readString(json, 'country_code'),
      nameZh: readString(json, 'name_zh'),
      nameEn: readString(json, 'name_en'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'country_code': countryCode,
      'name_zh': nameZh,
      'name_en': nameEn,
    };
  }
}

class SchoolVO {
  const SchoolVO({
    required this.schoolId,
    required this.nameZh,
    required this.nameEn,
    required this.nameLocal,
    required this.shortName,
    required this.country,
    required this.city,
    required this.schoolType,
    required this.is985,
    required this.is211,
    required this.isDoubleFirstClass,
  });

  final int schoolId;
  final String nameZh;
  final String nameEn;
  final String? nameLocal;
  final String? shortName;
  final String country;
  final String? city;
  final String schoolType;
  final bool is985;
  final bool is211;
  final bool isDoubleFirstClass;

  factory SchoolVO.fromJson(JsonMap json) {
    return SchoolVO(
      schoolId: readInt(json, 'schoolId'),
      nameZh: readString(json, 'nameZh'),
      nameEn: readString(json, 'nameEn'),
      nameLocal: _readNullableString(json['nameLocal']),
      shortName: _readNullableString(json['shortName']),
      country: readString(json, 'country'),
      city: _readNullableString(json['city']),
      schoolType: readString(json, 'schoolType'),
      is985: readBool(json, 'is985'),
      is211: readBool(json, 'is211'),
      isDoubleFirstClass: readBool(json, 'isDoubleFirstClass'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'schoolId': schoolId,
      'nameZh': nameZh,
      'nameEn': nameEn,
      'nameLocal': nameLocal,
      'shortName': shortName,
      'country': country,
      'city': city,
      'schoolType': schoolType,
      'is985': is985,
      'is211': is211,
      'isDoubleFirstClass': isDoubleFirstClass,
    };
  }
}

class PositionCategoryVO {
  const PositionCategoryVO({
    required this.categoryCode,
    required this.nameZh,
    required this.nameEn,
    required this.positions,
  });

  final String categoryCode;
  final String nameZh;
  final String nameEn;
  final List<PositionVO> positions;

  factory PositionCategoryVO.fromJson(JsonMap json) {
    return PositionCategoryVO(
      categoryCode: readString(json, 'category_code'),
      nameZh: readString(json, 'name_zh'),
      nameEn: readString(json, 'name_en'),
      positions: readModelList<PositionVO>(
        json,
        'positions',
        PositionVO.fromJson,
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'category_code': categoryCode,
      'name_zh': nameZh,
      'name_en': nameEn,
      'positions': positions.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class PositionVO {
  const PositionVO({
    required this.positionCode,
    required this.nameZh,
    required this.nameEn,
  });

  final String positionCode;
  final String nameZh;
  final String nameEn;

  factory PositionVO.fromJson(JsonMap json) {
    return PositionVO(
      positionCode: readString(json, 'position_code'),
      nameZh: readString(json, 'name_zh'),
      nameEn: readString(json, 'name_en'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'position_code': positionCode,
      'name_zh': nameZh,
      'name_en': nameEn,
    };
  }
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return null;
}
