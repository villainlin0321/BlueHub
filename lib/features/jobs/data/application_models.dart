import 'package:bluehub_app/shared/network/api_decoders.dart';

class ApplicantVO {
  const ApplicantVO({
    required this.userId,
    required this.nickname,
    required this.age,
    required this.gender,
    required this.experienceYears,
    required this.keyTags,
  });

  final int userId;
  final String nickname;
  final int age;
  final String gender;
  final int experienceYears;
  final List<String> keyTags;

  factory ApplicantVO.fromJson(JsonMap json) {
    return ApplicantVO(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      nickname: json['nickname'] as String? ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      keyTags: decodeStringList(json['keyTags'] ?? const <dynamic>[]),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'nickname': nickname,
      'age': age,
      'gender': gender,
      'experienceYears': experienceYears,
      'keyTags': keyTags,
    };
  }
}

class ApplicationVO {
  const ApplicationVO({
    required this.applicationId,
    required this.status,
    required this.matchScore,
    required this.job,
    required this.employer,
    required this.applicant,
    required this.submittedAt,
    required this.updatedAt,
  });

  final int applicationId;
  final String status;
  final int matchScore;
  final JobSimpleVO job;
  final EmployerSimpleVO employer;
  final ApplicantVO applicant;
  final String submittedAt;
  final String updatedAt;

  factory ApplicationVO.fromJson(JsonMap json) {
    return ApplicationVO(
      applicationId: (json['applicationId'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
      matchScore: (json['matchScore'] as num?)?.toInt() ?? 0,
      job: JobSimpleVO.fromJson(
        asJsonMap(json['job'] ?? const <String, dynamic>{}),
      ),
      employer: EmployerSimpleVO.fromJson(
        asJsonMap(json['employer'] ?? const <String, dynamic>{}),
      ),
      applicant: ApplicantVO.fromJson(
        asJsonMap(json['applicant'] ?? const <String, dynamic>{}),
      ),
      submittedAt: json['submittedAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'applicationId': applicationId,
      'status': status,
      'matchScore': matchScore,
      'job': job.toJson(),
      'employer': employer.toJson(),
      'applicant': applicant.toJson(),
      'submittedAt': submittedAt,
      'updatedAt': updatedAt,
    };
  }
}

class CreateApplicationBO {
  const CreateApplicationBO({required this.jobId});

  final int jobId;

  factory CreateApplicationBO.fromJson(JsonMap json) {
    return CreateApplicationBO(jobId: (json['jobId'] as num?)?.toInt() ?? 0);
  }

  JsonMap toJson() {
    return <String, dynamic>{'jobId': jobId};
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

class JobSimpleVO {
  const JobSimpleVO({
    required this.jobId,
    required this.title,
    required this.salaryMin,
    required this.salaryMax,
    required this.salaryCurrency,
  });

  final int jobId;
  final String title;
  final double salaryMin;
  final double salaryMax;
  final String salaryCurrency;

  factory JobSimpleVO.fromJson(JsonMap json) {
    return JobSimpleVO(
      jobId: (json['jobId'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      salaryMin: (json['salaryMin'] as num?)?.toDouble() ?? 0,
      salaryMax: (json['salaryMax'] as num?)?.toDouble() ?? 0,
      salaryCurrency: json['salaryCurrency'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'jobId': jobId,
      'title': title,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'salaryCurrency': salaryCurrency,
    };
  }
}

class UpdateApplicationStatusBO {
  const UpdateApplicationStatusBO({required this.status, required this.remark});

  final String status;
  final String remark;

  factory UpdateApplicationStatusBO.fromJson(JsonMap json) {
    return UpdateApplicationStatusBO(
      status: json['status'] as String? ?? '',
      remark: json['remark'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'status': status, 'remark': remark};
  }
}
