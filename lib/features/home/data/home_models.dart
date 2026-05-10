import 'package:bluehub_app/shared/network/api_decoders.dart';

class HomeHotPackageVO {
  const HomeHotPackageVO({
    required this.packageId,
    required this.packageName,
    required this.targetCountry,
    required this.priceFrom,
    required this.currency,
    required this.estimatedDays,
    required this.providerId,
    required this.providerName,
    required this.providerLogoUrl,
    required this.providerVerified,
    required this.rating,
    required this.caseCount,
    required this.description,
  });

  final int packageId;
  final String packageName;
  final String targetCountry;
  final double priceFrom;
  final String currency;
  final int estimatedDays;
  final int providerId;
  final String providerName;
  final String providerLogoUrl;
  final bool providerVerified;
  final double rating;
  final int caseCount;
  final String description;

  /// 安全解析首页热门签证套餐，避免字段类型漂移影响整个列表展示。
  factory HomeHotPackageVO.fromJson(JsonMap json) {
    return HomeHotPackageVO(
      packageId: readInt(json, 'packageId'),
      packageName: readString(json, 'packageName'),
      targetCountry: readString(json, 'targetCountry'),
      priceFrom: readDouble(json, 'priceFrom'),
      currency: readString(json, 'currency', fallback: 'CNY'),
      estimatedDays: readInt(json, 'estimatedDays'),
      providerId: readInt(json, 'providerId'),
      providerName: readString(json, 'providerName'),
      providerLogoUrl: readString(json, 'providerLogoUrl'),
      providerVerified: readBool(json, 'providerVerified'),
      rating: readDouble(json, 'rating'),
      caseCount: readInt(json, 'caseCount'),
      description: readString(json, 'description'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'packageId': packageId,
      'packageName': packageName,
      'targetCountry': targetCountry,
      'priceFrom': priceFrom,
      'currency': currency,
      'estimatedDays': estimatedDays,
      'providerId': providerId,
      'providerName': providerName,
      'providerLogoUrl': providerLogoUrl,
      'providerVerified': providerVerified,
      'rating': rating,
      'caseCount': caseCount,
      'description': description,
    };
  }
}
