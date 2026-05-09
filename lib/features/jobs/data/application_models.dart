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
      userId: readInt(json, 'userId'),
      nickname: readString(json, 'nickname'),
      age: readInt(json, 'age'),
      gender: readString(json, 'gender'),
      experienceYears: readInt(json, 'experienceYears'),
      keyTags: readStringList(json, 'keyTags'),
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
      applicationId: readInt(json, 'applicationId'),
      status: readString(json, 'status'),
      matchScore: readInt(json, 'matchScore'),
      job: JobSimpleVO.fromJson(
        readJsonMap(json, 'job'),
      ),
      employer: EmployerSimpleVO.fromJson(
        readJsonMap(json, 'employer'),
      ),
      applicant: ApplicantVO.fromJson(
        readJsonMap(json, 'applicant'),
      ),
      submittedAt: readString(json, 'submittedAt'),
      updatedAt: readString(json, 'updatedAt'),
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
    return CreateApplicationBO(jobId: readInt(json, 'jobId'));
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
      jobId: readInt(json, 'jobId'),
      title: readString(json, 'title'),
      salaryMin: readDouble(json, 'salaryMin'),
      salaryMax: readDouble(json, 'salaryMax'),
      salaryCurrency: readString(json, 'salaryCurrency'),
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
      status: readString(json, 'status'),
      remark: readString(json, 'remark'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'status': status, 'remark': remark};
  }
}
