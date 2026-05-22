import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import '../../../features/employer/data/employer_models.dart';

class EmployerService {
  EmployerService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 获取当前登录雇主的企业资料。
  Future<EmployerProfileVO> getEmployerProfile() async {
    final response = await _apiClient.get<EmployerProfileVO>(
      '/employer/me',
      decode: (data) => EmployerProfileVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 更新当前登录雇主的企业资料与联系人信息。
  Future<void> updateEmployerProfile({
    required UpdateEmployerBO request,
  }) async {
    return _apiClient.putVoid('/employer/me', data: request.toJson());
  }
}
