import 'package:bluehub_app/shared/network/api_decoders.dart';

class CreateJobBO {
  const CreateJobBO({
    required this.title,
    required this.country,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.headcount,
    required this.employmentType,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.salaryPeriod,
    required this.requirementTags,
    required this.customTags,
    required this.highlightTags,
    required this.hasVisaSupport,
    required this.isUrgent,
    required this.responsibilities,
    required this.requirements,
    required this.benefits,
    required this.description,
    required this.isDraft,
  });

  final String title;
  final String country;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final int headcount;
  final String employmentType;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;
  final String salaryPeriod;
  final List<String> requirementTags;
  final List<String> customTags;
  final List<String> highlightTags;
  final bool hasVisaSupport;
  final bool isUrgent;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> benefits;
  final String description;
  final bool isDraft;

  factory CreateJobBO.fromJson(JsonMap json) {
    return CreateJobBO(
      title: json['title'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      headcount: (json['headcount'] as num?)?.toInt() ?? 0,
      employmentType: json['employmentType'] as String? ?? '',
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
      salaryPeriod: json['salaryPeriod'] as String? ?? '',
      requirementTags: decodeStringList(
        json['requirementTags'] ?? const <dynamic>[],
      ),
      customTags: decodeStringList(json['customTags'] ?? const <dynamic>[]),
      highlightTags: decodeStringList(
        json['highlightTags'] ?? const <dynamic>[],
      ),
      hasVisaSupport: json['hasVisaSupport'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
      responsibilities: decodeStringList(
        json['responsibilities'] ?? const <dynamic>[],
      ),
      requirements: decodeStringList(json['requirements'] ?? const <dynamic>[]),
      benefits: decodeStringList(json['benefits'] ?? const <dynamic>[]),
      description: json['description'] as String? ?? '',
      isDraft: json['isDraft'] as bool? ?? false,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'title': title,
      'country': country,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'headcount': headcount,
      'employmentType': employmentType,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'salaryPeriod': salaryPeriod,
      'requirementTags': requirementTags,
      'customTags': customTags,
      'highlightTags': highlightTags,
      'hasVisaSupport': hasVisaSupport,
      'isUrgent': isUrgent,
      'responsibilities': responsibilities,
      'requirements': requirements,
      'benefits': benefits,
      'description': description,
      'isDraft': isDraft,
    };
  }
}

class EmployerInfoVO {
  const EmployerInfoVO({
    required this.employerId,
    required this.name,
    required this.industry,
    required this.size,
    required this.logoUrl,
  });

  final int employerId;
  final String name;
  final String industry;
  final String size;
  final String logoUrl;

  factory EmployerInfoVO.fromJson(JsonMap json) {
    return EmployerInfoVO(
      employerId: (json['employerId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      industry: json['industry'] as String? ?? '',
      size: json['size'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'employerId': employerId,
      'name': name,
      'industry': industry,
      'size': size,
      'logoUrl': logoUrl,
    };
  }
}

class EmployerSimpleVO {
  const EmployerSimpleVO({
    required this.employerId,
    required this.name,
    required this.logoUrl,
  });

  final int employerId;
  final String name;
  final String logoUrl;

  factory EmployerSimpleVO.fromJson(JsonMap json) {
    return EmployerSimpleVO(
      employerId: (json['employerId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'employerId': employerId,
      'name': name,
      'logoUrl': logoUrl,
    };
  }
}

class JobDetailVO {
  const JobDetailVO({
    required this.jobId,
    required this.title,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.salaryPeriod,
    required this.country,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.headcount,
    required this.employmentType,
    required this.tags,
    required this.hasVisaSupport,
    required this.isUrgent,
    required this.responsibilities,
    required this.requirements,
    required this.benefits,
    required this.description,
    required this.status,
    required this.employer,
    required this.viewCount,
    required this.applyCount,
    required this.isCollected,
    required this.publishedAt,
  });

  final int jobId;
  final String title;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;
  final String salaryPeriod;
  final String country;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final int headcount;
  final String employmentType;
  final List<TagVO> tags;
  final bool hasVisaSupport;
  final bool isUrgent;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> benefits;
  final String description;
  final String status;
  final EmployerInfoVO employer;
  final int viewCount;
  final int applyCount;
  final bool isCollected;
  final String publishedAt;

  factory JobDetailVO.fromJson(JsonMap json) {
    return JobDetailVO(
      jobId: (json['jobId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
      salaryPeriod: json['salaryPeriod'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      headcount: (json['headcount'] as num?)?.toInt() ?? 0,
      employmentType: json['employmentType'] as String? ?? '',
      tags: decodeModelList<TagVO>(
        json['tags'] ?? const <dynamic>[],
        TagVO.fromJson,
      ),
      hasVisaSupport: json['hasVisaSupport'] as bool? ?? false,
      isUrgent: json['isUrgent'] as bool? ?? false,
      responsibilities: decodeStringList(
        json['responsibilities'] ?? const <dynamic>[],
      ),
      requirements: decodeStringList(json['requirements'] ?? const <dynamic>[]),
      benefits: decodeStringList(json['benefits'] ?? const <dynamic>[]),
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      employer: EmployerInfoVO.fromJson(
        asJsonMap(json['employer'] ?? const <String, dynamic>{}),
      ),
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      applyCount: (json['applyCount'] as num?)?.toInt() ?? 0,
      isCollected: json['isCollected'] as bool? ?? false,
      publishedAt: json['publishedAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'title': title,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'salaryPeriod': salaryPeriod,
      'country': country,
      'city': city,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'headcount': headcount,
      'employmentType': employmentType,
      'tags': tags.map((item) => item.toJson()).toList(growable: false),
      'hasVisaSupport': hasVisaSupport,
      'isUrgent': isUrgent,
      'responsibilities': responsibilities,
      'requirements': requirements,
      'benefits': benefits,
      'description': description,
      'status': status,
      'employer': employer.toJson(),
      'viewCount': viewCount,
      'applyCount': applyCount,
      'isCollected': isCollected,
      'publishedAt': publishedAt,
    };
  }
}

class JobListVO {
  const JobListVO({
    required this.jobId,
    required this.title,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.salaryPeriod,
    required this.country,
    required this.city,
    required this.tags,
    required this.hasVisaSupport,
    required this.employer,
    required this.isUrgent,
    required this.isCollected,
    required this.publishedAt,
  });

  final int jobId;
  final String title;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;
  final String salaryPeriod;
  final String country;
  final String city;
  final List<TagVO> tags;
  final bool hasVisaSupport;
  final EmployerSimpleVO employer;
  final bool isUrgent;
  final bool isCollected;
  final String publishedAt;

  factory JobListVO.fromJson(JsonMap json) {
    return JobListVO(
      jobId: (json['jobId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
      salaryPeriod: json['salaryPeriod'] as String? ?? '',
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      tags: decodeModelList<TagVO>(
        json['tags'] ?? const <dynamic>[],
        TagVO.fromJson,
      ),
      hasVisaSupport: json['hasVisaSupport'] as bool? ?? false,
      employer: EmployerSimpleVO.fromJson(
        asJsonMap(json['employer'] ?? const <String, dynamic>{}),
      ),
      isUrgent: json['isUrgent'] as bool? ?? false,
      isCollected: json['isCollected'] as bool? ?? false,
      publishedAt: json['publishedAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'title': title,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'salaryPeriod': salaryPeriod,
      'country': country,
      'city': city,
      'tags': tags.map((item) => item.toJson()).toList(growable: false),
      'hasVisaSupport': hasVisaSupport,
      'employer': employer.toJson(),
      'isUrgent': isUrgent,
      'isCollected': isCollected,
      'publishedAt': publishedAt,
    };
  }
}

class TagVO {
  const TagVO({required this.type, required this.label, required this.color});

  final String type;
  final String label;
  final String color;

  factory TagVO.fromJson(JsonMap json) {
    return TagVO(
      type: json['type'] as String? ?? '',
      label: json['label'] as String? ?? '',
      color: json['color'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'type': type, 'label': label, 'color': color};
  }
}

class UpdateJobStatusBO {
  const UpdateJobStatusBO({required this.status});

  final String status;

  factory UpdateJobStatusBO.fromJson(JsonMap json) {
    return UpdateJobStatusBO(status: json['status'] as String? ?? '');
  }

  JsonMap toJson() {
    return <String, dynamic>{'status': status};
  }
}
