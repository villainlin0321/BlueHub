import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import '../../../features/me/data/resume_models.dart';

class ResumeService {
  ResumeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建一份新的空白简历。
  ///
  /// 返回值通常包含后端生成的新简历 ID 等字段。
  Future<Map<String, dynamic>> createResume() async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/resumes',
      decode: (data) => decodeMapValues<dynamic>(
        data ?? const <String, dynamic>{},
        (value) => value,
      ),
    );
    return response;
  }

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

  /// 获取当前用户的简历列表摘要。
  ///
  /// 列表按默认简历优先、更新时间倒序返回，可用于“我的简历”列表页。
  Future<List<ResumeListItemVO>> listMyResumes() async {
    final response = await _apiClient.get<List<ResumeListItemVO>>(
      '/resumes/mine',
      decode: (data) =>
          decodeModelList<ResumeListItemVO>(data, ResumeListItemVO.fromJson),
    );
    return response;
  }

  /// 根据用户 ID 获取简历详情。
  Future<ResumeVO> getResumeByUserId({required int userId}) async {
    final response = await _apiClient.get<ResumeVO>(
      '/resumes/user/$userId',
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
