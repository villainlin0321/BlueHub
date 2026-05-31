import 'package:easy_localization/easy_localization.dart';
import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import '../../../features/me/data/resume_models.dart';

class ResumeService {
  ResumeService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 创建一份新的空白简历，并返回后端生成的简历 ID。
  Future<int> createResume() async {
    final response = await _apiClient.post<JsonMap>(
      '/resumes',
      decode: (data) => asJsonMap(data),
    );
    final int? resumeId = _readCreatedResumeId(response);
    if (resumeId == null || resumeId <= 0) {
      throw StateError(tr('我的.创建简历缺少有效ID'));
    }
    return resumeId;
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

  int? _readCreatedResumeId(JsonMap response) {
    for (final String key in const <String>['resumeId', 'resume_id', 'id']) {
      final dynamic value = response[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final int? parsed = int.tryParse(value) ?? double.tryParse(value)?.toInt();
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
