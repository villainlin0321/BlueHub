import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/api_decoders.dart';
import '../../../features/employer/data/employer_models.dart';
import '../../../features/visa/data/provider_models.dart';

class EmployerService {
  EmployerService({
    required ApiClient apiClient,
    Future<void> Function()? onProfileUpdated,
  }) : _apiClient = apiClient,
       _onProfileUpdated = onProfileUpdated;

  final ApiClient _apiClient;
  final Future<void> Function()? _onProfileUpdated;

  /// 获取当前登录雇主的企业资料。
  Future<EmployerProfileVO> getEmployerProfile() async {
    final response = await _apiClient.get<EmployerProfileVO>(
      '/employer/me',
      decode: (data) => EmployerProfileVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 获取指定雇主的公开资料，供求职者端查看。
  Future<EmployerPublicVO> getPublicProfile({required int profileId}) async {
    final response = await _apiClient.get<EmployerPublicVO>(
      '/employer/$profileId',
      decode: (data) => EmployerPublicVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 更新当前登录雇主的企业资料与联系人信息。
  Future<void> updateEmployerProfile({
    required UpdateEmployerBO request,
  }) async {
    await _apiClient.putVoid('/employer/me', data: request.toJson());
    await _onProfileUpdated?.call();
  }

  /// 上传当前登录雇主的资质文档列表。
  Future<void> uploadQualifications({
    required UploadQualificationDocsBO request,
  }) async {
    return _apiClient.postVoid(
      '/employer/me/qualifications',
      data: request.toJson(),
    );
  }
}
