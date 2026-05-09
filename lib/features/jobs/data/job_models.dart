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

  /// 安全解析创建岗位请求模型，遇到字段类型不匹配时使用默认值兜底。
  factory CreateJobBO.fromJson(JsonMap json) {
    return CreateJobBO(
      title: readString(json, 'title'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
      address: readString(json, 'address'),
      latitude: readDouble(json, 'latitude'),
      longitude: readDouble(json, 'longitude'),
      headcount: readInt(json, 'headcount'),
      employmentType: readString(json, 'employmentType'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
      salaryPeriod: readString(json, 'salaryPeriod'),
      requirementTags: readStringList(json, 'requirementTags'),
      customTags: readStringList(json, 'customTags'),
      highlightTags: readStringList(json, 'highlightTags'),
      hasVisaSupport: readBool(json, 'hasVisaSupport'),
      isUrgent: readBool(json, 'isUrgent'),
      responsibilities: readStringList(json, 'responsibilities'),
      requirements: readStringList(json, 'requirements'),
      benefits: readStringList(json, 'benefits'),
      description: readString(json, 'description'),
      isDraft: readBool(json, 'isDraft'),
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

  /// 安全解析雇主信息，避免单个字段异常导致整条职位详情失败。
  factory EmployerInfoVO.fromJson(JsonMap json) {
    return EmployerInfoVO(
      employerId: readInt(json, 'employerId'),
      name: readString(json, 'name'),
      industry: readString(json, 'industry'),
      size: readString(json, 'size'),
      logoUrl: readString(json, 'logoUrl'),
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

  /// 安全解析雇主简要信息，避免后端字段类型漂移时直接抛异常。
  factory EmployerSimpleVO.fromJson(JsonMap json) {
    return EmployerSimpleVO(
      employerId: readInt(json, 'employerId'),
      name: readString(json, 'name'),
      logoUrl: readString(json, 'logoUrl'),
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

  /// 安全解析职位详情模型，确保嵌套对象和数组在异常数据下也能兜底。
  factory JobDetailVO.fromJson(JsonMap json) {
    return JobDetailVO(
      jobId: readInt(json, 'jobId'),
      title: readString(json, 'title'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
      salaryPeriod: readString(json, 'salaryPeriod'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
      address: readString(json, 'address'),
      latitude: readDouble(json, 'latitude'),
      longitude: readDouble(json, 'longitude'),
      headcount: readInt(json, 'headcount'),
      employmentType: readString(json, 'employmentType'),
      tags: readModelList<TagVO>(json, 'tags', TagVO.fromJson),
      hasVisaSupport: readBool(json, 'hasVisaSupport'),
      isUrgent: readBool(json, 'isUrgent'),
      responsibilities: readStringList(json, 'responsibilities'),
      requirements: readStringList(json, 'requirements'),
      benefits: readStringList(json, 'benefits'),
      description: readString(json, 'description'),
      status: readString(json, 'status'),
      employer: EmployerInfoVO.fromJson(
        readJsonMap(json, 'employer'),
      ),
      viewCount: readInt(json, 'viewCount'),
      applyCount: readInt(json, 'applyCount'),
      isCollected: readBool(json, 'isCollected'),
      publishedAt: readString(json, 'publishedAt'),
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

  /// 安全解析职位列表模型，避免字段类型抖动影响整页列表渲染。
  factory JobListVO.fromJson(JsonMap json) {
    return JobListVO(
      jobId: readInt(json, 'jobId'),
      title: readString(json, 'title'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
      salaryPeriod: readString(json, 'salaryPeriod'),
      country: readString(json, 'country'),
      city: readString(json, 'city'),
      tags: readModelList<TagVO>(json, 'tags', TagVO.fromJson),
      hasVisaSupport: readBool(json, 'hasVisaSupport'),
      employer: EmployerSimpleVO.fromJson(
        readJsonMap(json, 'employer'),
      ),
      isUrgent: readBool(json, 'isUrgent'),
      isCollected: readBool(json, 'isCollected'),
      publishedAt: readString(json, 'publishedAt'),
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

  /// 安全解析标签模型，字段不合法时回退为空字符串。
  factory TagVO.fromJson(JsonMap json) {
    return TagVO(
      type: readString(json, 'type'),
      label: readString(json, 'label'),
      color: readString(json, 'color'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'type': type, 'label': label, 'color': color};
  }
}

class UpdateJobStatusBO {
  const UpdateJobStatusBO({required this.status});

  final String status;

  /// 安全解析更新岗位状态请求，兼容后端把状态字段返回为非字符串的情况。
  factory UpdateJobStatusBO.fromJson(JsonMap json) {
    return UpdateJobStatusBO(status: readString(json, 'status'));
  }

  JsonMap toJson() {
    return <String, dynamic>{'status': status};
  }
}
