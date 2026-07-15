import 'package:europepass/shared/network/api_decoders.dart';

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
    this.aiContent,
    this.activeJobs,
    this.receivedResumes,
    this.pendingInterviews,
    this.hired,
    this.orderCount,
    this.resumeCompleteness,
    this.applicationCount,
    this.collectionCount,
  });

  final int? todayConsultations;
  final int? inProgressOrders;
  final String monthlyIncome;
  final String incomeCurrency;
  final String? aiContent;
  final int? activeJobs;
  final int? receivedResumes;
  final int? pendingInterviews;
  final int? hired;
  final int? orderCount;
  final int? resumeCompleteness;
  final int? applicationCount;
  final int? collectionCount;

  factory HomeDashboardStatsVO.fromJson(JsonMap json) {
    return HomeDashboardStatsVO(
      todayConsultations: _readNullableInt(json['todayConsultations']),
      inProgressOrders: _readNullableInt(json['inProgressOrders']),
      monthlyIncome: _readNumberAsString(json['monthlyIncome']) ?? '0',
      incomeCurrency: readString(json, 'incomeCurrency', fallback: 'CNY'),
      aiContent: _readNullableString(json['aiContent']),
      activeJobs: _readNullableInt(json['activeJobs']),
      receivedResumes: _readNullableInt(json['receivedResumes']),
      pendingInterviews: _readNullableInt(json['pendingInterviews']),
      hired: _readNullableInt(json['hired']),
      orderCount: _readNullableInt(json['orderCount']),
      resumeCompleteness: _readNullableInt(json['resumeCompleteness']),
      applicationCount: _readNullableInt(json['applicationCount']),
      collectionCount: _readNullableInt(json['collectionCount']),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'todayConsultations': todayConsultations,
      'inProgressOrders': inProgressOrders,
      'monthlyIncome': monthlyIncome,
      'incomeCurrency': incomeCurrency,
      'aiContent': aiContent,
      'activeJobs': activeJobs,
      'receivedResumes': receivedResumes,
      'pendingInterviews': pendingInterviews,
      'hired': hired,
      'orderCount': orderCount,
      'resumeCompleteness': resumeCompleteness,
      'applicationCount': applicationCount,
      'collectionCount': collectionCount,
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

String? _readNumberAsString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  if (value is int) {
    return value.toString();
  }
  if (value is double) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
  if (value is num) {
    final double normalized = value.toDouble();
    return normalized % 1 == 0
        ? normalized.toStringAsFixed(0)
        : normalized.toString();
  }
  return null;
}

String? _readNullableString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}
