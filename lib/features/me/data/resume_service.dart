import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'resume_models.dart';

class ResumeService {
  ResumeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ResumeVO> getMyResume() async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/me',
      decode: (data) => ResumeVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> saveResume({required SaveResumeBO request}) async {
    return _apiClient.putVoid('/resumes/me', data: request.toJson());
  }

  Future<ResumeVO> getResumeByUserId({required int userId}) async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/$userId',
      decode: (data) => ResumeVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<ResumeVO> getResumeDetail({required int resumeId}) async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/$resumeId',
      decode: (data) => ResumeVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> updateResume({
    required int resumeId,
    required SaveResumeBO request,
  }) async {
    return _apiClient.putVoid('/resumes/$resumeId', data: request.toJson());
  }

  Future<void> deleteResume({required int resumeId}) async {
    return _apiClient.deleteVoid('/resumes/$resumeId');
  }

  Future<void> setDefaultResume({required int resumeId}) async {
    return _apiClient.putVoid('/resumes/$resumeId/default');
  }
}
