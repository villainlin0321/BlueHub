import 'package:bluehub_app/shared/network/api_decoders.dart';

class TalentVO {
  const TalentVO({
    required this.resumeId,
    required this.userId,
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.age,
    required this.completeness,
    required this.yearsOfExperience,
    required this.targetPositions,
    required this.targetCountries,
    required this.selfEvaluation,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
    required this.updatedAt,
  });

  final int resumeId;
  final int userId;
  final String nickname;
  final String avatarUrl;
  final String gender;
  final int? age;
  final int completeness;
  final int yearsOfExperience;
  final List<String> targetPositions;
  final List<String> targetCountries;
  final String selfEvaluation;
  final double? salaryMin;
  final double? salaryMax;
  final String salaryCurrency;
  final String updatedAt;

  factory TalentVO.fromJson(JsonMap json) {
    return TalentVO(
      resumeId: readInt(json, 'resume_id'),
      userId: readInt(json, 'user_id'),
      nickname: readString(json, 'nickname'),
      avatarUrl: readString(json, 'avatar_url'),
      gender: readString(json, 'gender'),
      age: _readNullableInt(json['age']),
      completeness: readInt(json, 'completeness'),
      yearsOfExperience: readInt(json, 'years_of_experience'),
      targetPositions: readStringList(json, 'target_positions'),
      targetCountries: readStringList(json, 'target_countries'),
      selfEvaluation: readString(json, 'self_evaluation'),
      salaryMin: _readNullableDouble(json['salary_min']),
      salaryMax: _readNullableDouble(json['salary_max']),
      salaryCurrency: readString(json, 'salary_currency', fallback: 'EUR'),
      updatedAt: readString(json, 'updated_at'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'resume_id': resumeId,
      'user_id': userId,
      'nickname': nickname,
      'avatar_url': avatarUrl,
      'gender': gender,
      'age': age,
      'completeness': completeness,
      'years_of_experience': yearsOfExperience,
      'target_positions': targetPositions,
      'target_countries': targetCountries,
      'self_evaluation': selfEvaluation,
      'salary_min': salaryMin,
      'salary_max': salaryMax,
      'salary_currency': salaryCurrency,
      'updated_at': updatedAt,
    };
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

double? _readNullableDouble(dynamic value) {
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
  return null;
}
