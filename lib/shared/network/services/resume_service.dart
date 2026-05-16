import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import '../../../features/me/data/resume_models.dart';

class ResumeService {
  ResumeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取当前登录用户的简历。
  Future<ResumeVO> getMyResume() async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/me',
      decode: (data) => ResumeVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 保存当前登录用户的简历内容。
  Future<void> saveResume({required SaveResumeBO request}) async {
    return _apiClient.putVoid('/resumes/me', data: request.toJson());
  }

  /// 根据用户 ID 获取简历详情。
  Future<ResumeVO> getResumeByUserId({required int userId}) async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/$userId',
      decode: (data) => ResumeVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 获取指定简历的完整详情。
  Future<ResumeVO> getResumeDetail({required int resumeId}) async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/$resumeId',
      decode: (data) => ResumeVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 全量更新指定简历内容。
  Future<void> updateResume({
    required int resumeId,
    required SaveResumeBO request,
  }) async {
    return _apiClient.putVoid('/resumes/$resumeId', data: request.toJson());
  }

  /// 删除指定简历。
  Future<void> deleteResume({required int resumeId}) async {
    return _apiClient.deleteVoid('/resumes/$resumeId');
  }

  /// 将指定简历设为默认简历。
  Future<void> setDefaultResume({required int resumeId}) async {
    return _apiClient.putVoid('/resumes/$resumeId/default');
  }
}
