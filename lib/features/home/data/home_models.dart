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

class HomeDashboardStatsVO {
  const HomeDashboardStatsVO({
    this.todayConsultations,
    this.inProgressOrders,
    required this.monthlyIncome,
    required this.incomeCurrency,
    this.activeJobs,
    this.receivedResumes,
    this.pendingInterviews,
    this.hired,
  });

  final int? todayConsultations;
  final int? inProgressOrders;
  final String monthlyIncome;
  final String incomeCurrency;
  final int? activeJobs;
  final int? receivedResumes;
  final int? pendingInterviews;
  final int? hired;

  factory HomeDashboardStatsVO.fromJson(JsonMap json) {
    return HomeDashboardStatsVO(
      todayConsultations: _readNullableInt(json['todayConsultations']),
      inProgressOrders: _readNullableInt(json['inProgressOrders']),
      monthlyIncome: readString(json, 'monthlyIncome', fallback: '0'),
      incomeCurrency: readString(json, 'incomeCurrency', fallback: 'CNY'),
      activeJobs: _readNullableInt(json['activeJobs']),
      receivedResumes: _readNullableInt(json['receivedResumes']),
      pendingInterviews: _readNullableInt(json['pendingInterviews']),
      hired: _readNullableInt(json['hired']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'todayConsultations': todayConsultations,
      'inProgressOrders': inProgressOrders,
      'monthlyIncome': monthlyIncome,
      'incomeCurrency': incomeCurrency,
      'activeJobs': activeJobs,
      'receivedResumes': receivedResumes,
      'pendingInterviews': pendingInterviews,
      'hired': hired,
    };
  }

  String get incomeCurrencySymbol {
    return switch (incomeCurrency.trim().toUpperCase()) {
      'CNY' || 'RMB' => '¥',
      'EUR' => '€',
      'USD' => '\$',
      _ => incomeCurrency.trim().isEmpty ? '¥' : incomeCurrency.trim(),
    };
  }

  String get monthlyIncomeDisplay {
    final String value = monthlyIncome.trim();
    return value.isEmpty ? '0' : value;
  }
}

int? _readNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt();
  }
  return null;
}
