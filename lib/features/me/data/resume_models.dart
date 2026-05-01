import 'package:bluehub_app/shared/network/api_decoders.dart';

class BasicInfoVO {
  const BasicInfoVO({
    required this.realName,
    required this.gender,
    required this.age,
    required this.phone,
    required this.currentLocation,
    required this.avatarUrl,
  });

  final String realName;
  final String gender;
  final int age;
  final String phone;
  final String currentLocation;
  final String avatarUrl;

  factory BasicInfoVO.fromJson(JsonMap json) {
    return BasicInfoVO(
      realName: json['realName'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      currentLocation: json['currentLocation'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'realName': realName,
      'gender': gender,
      'age': age,
      'phone': phone,
      'currentLocation': currentLocation,
      'avatarUrl': avatarUrl,
    };
  }
}

class EducationBO {
  const EducationBO({
    required this.eduId,
    required this.school,
    required this.major,
    required this.degree,
    required this.startYear,
    required this.endYear,
    required this.sortOrder,
  });

  final int eduId;
  final String school;
  final String major;
  final String degree;
  final int startYear;
  final int endYear;
  final int sortOrder;

  factory EducationBO.fromJson(JsonMap json) {
    return EducationBO(
      eduId: (json['eduId'] as num?)?.toInt() ?? 0,
      school: json['school'] as String? ?? '',
      major: json['major'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      startYear: (json['startYear'] as num?)?.toInt() ?? 0,
      endYear: (json['endYear'] as num?)?.toInt() ?? 0,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'eduId': eduId,
      'school': school,
      'major': major,
      'degree': degree,
      'startYear': startYear,
      'endYear': endYear,
      'sortOrder': sortOrder,
    };
  }
}

class EducationVO {
  const EducationVO({
    required this.eduId,
    required this.school,
    required this.major,
    required this.degree,
    required this.startYear,
    required this.endYear,
  });

  final int eduId;
  final String school;
  final String major;
  final String degree;
  final int startYear;
  final int endYear;

  factory EducationVO.fromJson(JsonMap json) {
    return EducationVO(
      eduId: (json['eduId'] as num?)?.toInt() ?? 0,
      school: json['school'] as String? ?? '',
      major: json['major'] as String? ?? '',
      degree: json['degree'] as String? ?? '',
      startYear: (json['startYear'] as num?)?.toInt() ?? 0,
      endYear: (json['endYear'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'eduId': eduId,
      'school': school,
      'major': major,
      'degree': degree,
      'startYear': startYear,
      'endYear': endYear,
    };
  }
}

class JobIntentionBO {
  const JobIntentionBO({
    required this.positions,
    required this.countries,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
  });

  final List<String> positions;
  final List<String> countries;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;

  factory JobIntentionBO.fromJson(JsonMap json) {
    return JobIntentionBO(
      positions: decodeStringList(json['positions'] ?? const <dynamic>[]),
      countries: decodeStringList(json['countries'] ?? const <dynamic>[]),
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'positions': positions,
      'countries': countries,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
    };
  }
}

class JobIntentionVO {
  const JobIntentionVO({
    required this.positions,
    required this.countries,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
  });

  final List<String> positions;
  final List<String> countries;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;

  factory JobIntentionVO.fromJson(JsonMap json) {
    return JobIntentionVO(
      positions: decodeStringList(json['positions'] ?? const <dynamic>[]),
      countries: decodeStringList(json['countries'] ?? const <dynamic>[]),
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'positions': positions,
      'countries': countries,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
    };
  }
}

class LanguageAbilityBO {
  const LanguageAbilityBO({
    required this.langId,
    required this.language,
    required this.certificate,
    required this.level,
    required this.sortOrder,
  });

  final int langId;
  final String language;
  final String certificate;
  final String level;
  final int sortOrder;

  factory LanguageAbilityBO.fromJson(JsonMap json) {
    return LanguageAbilityBO(
      langId: (json['langId'] as num?)?.toInt() ?? 0,
      language: json['language'] as String? ?? '',
      certificate: json['certificate'] as String? ?? '',
      level: json['level'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'langId': langId,
      'language': language,
      'certificate': certificate,
      'level': level,
      'sortOrder': sortOrder,
    };
  }
}

class LanguageAbilityVO {
  const LanguageAbilityVO({
    required this.langId,
    required this.language,
    required this.certificate,
    required this.level,
  });

  final int langId;
  final String language;
  final String certificate;
  final String level;

  factory LanguageAbilityVO.fromJson(JsonMap json) {
    return LanguageAbilityVO(
      langId: (json['langId'] as num?)?.toInt() ?? 0,
      language: json['language'] as String? ?? '',
      certificate: json['certificate'] as String? ?? '',
      level: json['level'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'langId': langId,
      'language': language,
      'certificate': certificate,
      'level': level,
    };
  }
}

class ResumeVO {
  const ResumeVO({
    required this.resumeId,
    required this.completeness,
    required this.basicInfo,
    required this.jobIntention,
    required this.workExperiences,
    required this.languages,
    required this.skillCertificates,
    required this.educations,
    required this.selfEvaluation,
    required this.updatedAt,
  });

  final int resumeId;
  final int completeness;
  final BasicInfoVO basicInfo;
  final JobIntentionVO jobIntention;
  final List<WorkExperienceVO> workExperiences;
  final List<LanguageAbilityVO> languages;
  final List<SkillCertificateVO> skillCertificates;
  final List<EducationVO> educations;
  final String selfEvaluation;
  final String updatedAt;

  factory ResumeVO.fromJson(JsonMap json) {
    return ResumeVO(
      resumeId: (json['resumeId'] as num?)?.toInt() ?? 0,
      completeness: (json['completeness'] as num?)?.toInt() ?? 0,
      basicInfo: BasicInfoVO.fromJson(
        asJsonMap(json['basicInfo'] ?? const <String, dynamic>{}),
      ),
      jobIntention: JobIntentionVO.fromJson(
        asJsonMap(json['jobIntention'] ?? const <String, dynamic>{}),
      ),
      workExperiences: decodeModelList<WorkExperienceVO>(
        json['workExperiences'] ?? const <dynamic>[],
        WorkExperienceVO.fromJson,
      ),
      languages: decodeModelList<LanguageAbilityVO>(
        json['languages'] ?? const <dynamic>[],
        LanguageAbilityVO.fromJson,
      ),
      skillCertificates: decodeModelList<SkillCertificateVO>(
        json['skillCertificates'] ?? const <dynamic>[],
        SkillCertificateVO.fromJson,
      ),
      educations: decodeModelList<EducationVO>(
        json['educations'] ?? const <dynamic>[],
        EducationVO.fromJson,
      ),
      selfEvaluation: json['selfEvaluation'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'resumeId': resumeId,
      'completeness': completeness,
      'basicInfo': basicInfo.toJson(),
      'jobIntention': jobIntention.toJson(),
      'workExperiences': workExperiences
          .map((item) => item.toJson())
          .toList(growable: false),
      'languages': languages
          .map((item) => item.toJson())
          .toList(growable: false),
      'skillCertificates': skillCertificates
          .map((item) => item.toJson())
          .toList(growable: false),
      'educations': educations
          .map((item) => item.toJson())
          .toList(growable: false),
      'selfEvaluation': selfEvaluation,
      'updatedAt': updatedAt,
    };
  }
}

class SaveResumeBO {
  const SaveResumeBO({
    required this.jobIntention,
    required this.workExperiences,
    required this.languages,
    required this.skillCertificates,
    required this.educations,
    required this.selfEvaluation,
    required this.isPublic,
  });

  final JobIntentionBO jobIntention;
  final List<WorkExperienceBO> workExperiences;
  final List<LanguageAbilityBO> languages;
  final List<SkillCertificateBO> skillCertificates;
  final List<EducationBO> educations;
  final String selfEvaluation;
  final bool isPublic;

  factory SaveResumeBO.fromJson(JsonMap json) {
    return SaveResumeBO(
      jobIntention: JobIntentionBO.fromJson(
        asJsonMap(json['jobIntention'] ?? const <String, dynamic>{}),
      ),
      workExperiences: decodeModelList<WorkExperienceBO>(
        json['workExperiences'] ?? const <dynamic>[],
        WorkExperienceBO.fromJson,
      ),
      languages: decodeModelList<LanguageAbilityBO>(
        json['languages'] ?? const <dynamic>[],
        LanguageAbilityBO.fromJson,
      ),
      skillCertificates: decodeModelList<SkillCertificateBO>(
        json['skillCertificates'] ?? const <dynamic>[],
        SkillCertificateBO.fromJson,
      ),
      educations: decodeModelList<EducationBO>(
        json['educations'] ?? const <dynamic>[],
        EducationBO.fromJson,
      ),
      selfEvaluation: json['selfEvaluation'] as String? ?? '',
      isPublic: json['isPublic'] as bool? ?? false,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'jobIntention': jobIntention.toJson(),
      'workExperiences': workExperiences
          .map((item) => item.toJson())
          .toList(growable: false),
      'languages': languages
          .map((item) => item.toJson())
          .toList(growable: false),
      'skillCertificates': skillCertificates
          .map((item) => item.toJson())
          .toList(growable: false),
      'educations': educations
          .map((item) => item.toJson())
          .toList(growable: false),
      'selfEvaluation': selfEvaluation,
      'isPublic': isPublic,
    };
  }
}

class SkillCertificateBO {
  const SkillCertificateBO({
    required this.certId,
    required this.name,
    required this.level,
    required this.issuer,
    required this.issuedDate,
    required this.imageUrl,
    required this.sortOrder,
  });

  final int certId;
  final String name;
  final String level;
  final String issuer;
  final String issuedDate;
  final String imageUrl;
  final int sortOrder;

  factory SkillCertificateBO.fromJson(JsonMap json) {
    return SkillCertificateBO(
      certId: (json['certId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      level: json['level'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      issuedDate: json['issuedDate'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'certId': certId,
      'name': name,
      'level': level,
      'issuer': issuer,
      'issuedDate': issuedDate,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
    };
  }
}

class SkillCertificateVO {
  const SkillCertificateVO({
    required this.certId,
    required this.name,
    required this.level,
    required this.issuer,
    required this.issuedDate,
    required this.imageUrl,
  });

  final int certId;
  final String name;
  final String level;
  final String issuer;
  final String issuedDate;
  final String imageUrl;

  factory SkillCertificateVO.fromJson(JsonMap json) {
    return SkillCertificateVO(
      certId: (json['certId'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      level: json['level'] as String? ?? '',
      issuer: json['issuer'] as String? ?? '',
      issuedDate: json['issuedDate'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'certId': certId,
      'name': name,
      'level': level,
      'issuer': issuer,
      'issuedDate': issuedDate,
      'imageUrl': imageUrl,
    };
  }
}

class WorkExperienceBO {
  const WorkExperienceBO({
    required this.expId,
    required this.company,
    required this.department,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.description,
    required this.sortOrder,
  });

  final int expId;
  final String company;
  final String department;
  final String position;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final String description;
  final int sortOrder;

  factory WorkExperienceBO.fromJson(JsonMap json) {
    return WorkExperienceBO(
      expId: (json['expId'] as num?)?.toInt() ?? 0,
      company: json['company'] as String? ?? '',
      department: json['department'] as String? ?? '',
      position: json['position'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      isCurrent: json['isCurrent'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'expId': expId,
      'company': company,
      'department': department,
      'position': position,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'description': description,
      'sortOrder': sortOrder,
    };
  }
}

class WorkExperienceVO {
  const WorkExperienceVO({
    required this.expId,
    required this.company,
    required this.department,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.description,
  });

  final int expId;
  final String company;
  final String department;
  final String position;
  final String startDate;
  final String endDate;
  final bool isCurrent;
  final String description;

  factory WorkExperienceVO.fromJson(JsonMap json) {
    return WorkExperienceVO(
      expId: (json['expId'] as num?)?.toInt() ?? 0,
      company: json['company'] as String? ?? '',
      department: json['department'] as String? ?? '',
      position: json['position'] as String? ?? '',
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
      isCurrent: json['isCurrent'] as bool? ?? false,
      description: json['description'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'expId': expId,
      'company': company,
      'department': department,
      'position': position,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'description': description,
    };
  }
}
