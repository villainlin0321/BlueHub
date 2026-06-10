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
      realName: readString(json, 'realName'),
      gender: readString(json, 'gender'),
      age: readInt(json, 'age'),
      phone: readString(json, 'phone'),
      currentLocation: readString(json, 'currentLocation'),
      avatarUrl: readString(json, 'avatarUrl'),
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
      eduId: readInt(json, 'eduId'),
      school: readString(json, 'school'),
      major: readString(json, 'major'),
      degree: readString(json, 'degree'),
      startYear: readInt(json, 'startYear'),
      endYear: readInt(json, 'endYear'),
      sortOrder: readInt(json, 'sortOrder'),
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
      eduId: readInt(json, 'eduId'),
      school: readString(json, 'school'),
      major: readString(json, 'major'),
      degree: readString(json, 'degree'),
      startYear: readInt(json, 'startYear'),
      endYear: readInt(json, 'endYear'),
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
      positions: readStringList(json, 'positions'),
      countries: readStringList(json, 'countries'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
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
      positions: readStringList(json, 'positions'),
      countries: readStringList(json, 'countries'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
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
      langId: readInt(json, 'langId'),
      language: readString(json, 'language'),
      certificate: readString(json, 'certificate'),
      level: readString(json, 'level'),
      sortOrder: readInt(json, 'sortOrder'),
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
      langId: readInt(json, 'langId'),
      language: readString(json, 'language'),
      certificate: readString(json, 'certificate'),
      level: readString(json, 'level'),
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

class ResumeListItemVO {
  const ResumeListItemVO({
    required this.resumeId,
    required this.isDefault,
    required this.completeness,
    required this.targetPositions,
    required this.targetCountries,
    required this.isPublic,
    required this.updatedAt,
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.age,
    required this.currentLocation,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.latestExperience,
  });

  final int resumeId;
  final bool isDefault;
  final int completeness;
  final List<String> targetPositions;
  final List<String> targetCountries;
  final bool isPublic;
  final String updatedAt;
  final String nickname;
  final String avatarUrl;
  final String gender;
  final int? age;
  final String currentLocation;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCurrency;
  final LatestExperienceVO? latestExperience;

  factory ResumeListItemVO.fromJson(JsonMap json) {
    return ResumeListItemVO(
      resumeId: _readIntByKeys(json, const ['resume_id', 'resumeId']),
      isDefault: _readBoolByKeys(json, const ['is_default', 'isDefault']),
      completeness: readInt(json, 'completeness'),
      targetPositions: _readStringListByKeys(json, const [
        'target_positions',
        'targetPositions',
      ]),
      targetCountries: _readStringListByKeys(json, const [
        'target_countries',
        'targetCountries',
      ]),
      isPublic: _readBoolByKeys(json, const ['is_public', 'isPublic']),
      updatedAt: _readStringByKeys(json, const ['updated_at', 'updatedAt']),
      nickname: readString(json, 'nickname'),
      avatarUrl: _readStringByKeys(json, const ['avatar_url', 'avatarUrl']),
      gender: readString(json, 'gender'),
      age: _readNullableIntByKeys(json, const ['age']),
      currentLocation: _readStringByKeys(json, const [
        'current_location',
        'currentLocation',
      ]),
      salaryMin: _readNullableDoubleByKeys(json, const [
        'salary_min',
        'salaryMin',
      ]),
      salaryMax: _readNullableDoubleByKeys(json, const [
        'salary_max',
        'salaryMax',
      ]),
      salaryCurrency: _readStringByKeys(json, const [
        'salary_currency',
        'salaryCurrency',
      ]),
      latestExperience: _readLatestExperience(json, const [
        'latest_experience',
        'latestExperience',
      ]),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'resumeId': resumeId,
      'isDefault': isDefault,
      'completeness': completeness,
      'targetPositions': targetPositions,
      'targetCountries': targetCountries,
      'isPublic': isPublic,
      'updatedAt': updatedAt,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'age': age,
      'currentLocation': currentLocation,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
      'latestExperience': latestExperience?.toJson(),
    };
  }
}

class LatestExperienceVO {
  const LatestExperienceVO({
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
    required this.description,
  });

  final String company;
  final String position;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String description;

  factory LatestExperienceVO.fromJson(JsonMap json) {
    return LatestExperienceVO(
      company: readString(json, 'company'),
      position: readString(json, 'position'),
      startDate: _readStringByKeys(json, const ['start_date', 'startDate']),
      endDate: _readNullableStringByKeys(json, const ['end_date', 'endDate']),
      isCurrent: _readBoolByKeys(json, const ['is_current', 'isCurrent']),
      description: readString(json, 'description'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'company': company,
      'position': position,
      'startDate': startDate,
      'endDate': endDate,
      'isCurrent': isCurrent,
      'description': description,
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
    required this.isPublic,
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
  final bool? isPublic;
  final String updatedAt;

  /// 安全解析简历详情；`isPublic` 在文档中未声明时允许为空，避免误判可见性。
  factory ResumeVO.fromJson(JsonMap json) {
    return ResumeVO(
      resumeId: readInt(json, 'resumeId'),
      completeness: readInt(json, 'completeness'),
      basicInfo: BasicInfoVO.fromJson(readJsonMap(json, 'basicInfo')),
      jobIntention: JobIntentionVO.fromJson(readJsonMap(json, 'jobIntention')),
      workExperiences: readModelList<WorkExperienceVO>(
        json,
        'workExperiences',
        WorkExperienceVO.fromJson,
      ),
      languages: readModelList<LanguageAbilityVO>(
        json,
        'languages',
        LanguageAbilityVO.fromJson,
      ),
      skillCertificates: readModelList<SkillCertificateVO>(
        json,
        'skillCertificates',
        SkillCertificateVO.fromJson,
      ),
      educations: readModelList<EducationVO>(
        json,
        'educations',
        EducationVO.fromJson,
      ),
      selfEvaluation: readString(json, 'selfEvaluation'),
      isPublic: json.containsKey('isPublic')
          ? readBool(json, 'isPublic')
          : null,
      updatedAt: readString(json, 'updatedAt'),
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
      if (isPublic != null) 'isPublic': isPublic,
      'updatedAt': updatedAt,
    };
  }
}

String _readStringByKeys(
  JsonMap json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return readString(json, key, fallback: fallback);
    }
  }
  return fallback;
}

String? _readNullableStringByKeys(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final value = json[key];
    if (value == null) {
      return null;
    }
    return readString(json, key);
  }
  return null;
}

int _readIntByKeys(JsonMap json, List<String> keys, {int fallback = 0}) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return readInt(json, key, fallback: fallback);
    }
  }
  return fallback;
}

bool _readBoolByKeys(JsonMap json, List<String> keys, {bool fallback = false}) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return readBool(json, key, fallback: fallback);
    }
  }
  return fallback;
}

List<String> _readStringListByKeys(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) {
      return readStringList(json, key);
    }
  }
  return const <String>[];
}

int? _readNullableIntByKeys(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final value = json[key];
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
  }
  return null;
}

double? _readNullableDoubleByKeys(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key)) {
      continue;
    }
    final value = json[key];
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
  }
  return null;
}

LatestExperienceVO? _readLatestExperience(JsonMap json, List<String> keys) {
  for (final key in keys) {
    if (!json.containsKey(key) || json[key] == null) {
      continue;
    }
    final nested = readJsonMap(json, key);
    if (nested.isEmpty) {
      return null;
    }
    return LatestExperienceVO.fromJson(nested);
  }
  return null;
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
      jobIntention: JobIntentionBO.fromJson(readJsonMap(json, 'jobIntention')),
      workExperiences: readModelList<WorkExperienceBO>(
        json,
        'workExperiences',
        WorkExperienceBO.fromJson,
      ),
      languages: readModelList<LanguageAbilityBO>(
        json,
        'languages',
        LanguageAbilityBO.fromJson,
      ),
      skillCertificates: readModelList<SkillCertificateBO>(
        json,
        'skillCertificates',
        SkillCertificateBO.fromJson,
      ),
      educations: readModelList<EducationBO>(
        json,
        'educations',
        EducationBO.fromJson,
      ),
      selfEvaluation: readString(json, 'selfEvaluation'),
      isPublic: readBool(json, 'isPublic'),
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
      certId: readInt(json, 'certId'),
      name: readString(json, 'name'),
      level: readString(json, 'level'),
      issuer: readString(json, 'issuer'),
      issuedDate: readString(json, 'issuedDate'),
      imageUrl: readString(json, 'imageUrl'),
      sortOrder: readInt(json, 'sortOrder'),
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
      certId: readInt(json, 'certId'),
      name: readString(json, 'name'),
      level: readString(json, 'level'),
      issuer: readString(json, 'issuer'),
      issuedDate: readString(json, 'issuedDate'),
      imageUrl: readString(json, 'imageUrl'),
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
      expId: readInt(json, 'expId'),
      company: readString(json, 'company'),
      department: readString(json, 'department'),
      position: readString(json, 'position'),
      startDate: readString(json, 'startDate'),
      endDate: readString(json, 'endDate'),
      isCurrent: readBool(json, 'isCurrent'),
      description: readString(json, 'description'),
      sortOrder: readInt(json, 'sortOrder'),
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
      expId: readInt(json, 'expId'),
      company: readString(json, 'company'),
      department: readString(json, 'department'),
      position: readString(json, 'position'),
      startDate: readString(json, 'startDate'),
      endDate: readString(json, 'endDate'),
      isCurrent: readBool(json, 'isCurrent'),
      description: readString(json, 'description'),
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
