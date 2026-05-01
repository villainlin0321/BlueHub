import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'employer_models.dart';

class EmployerService {
  EmployerService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<EmployerProfileVO> getEmployerProfile() async {
    final response = await _apiClient.get<EmployerProfileVO>(
      '/employer/me',
      decode: (data) => EmployerProfileVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> updateEmployerProfile({
    required UpdateEmployerBO request,
  }) async {
    return _apiClient.putVoid('/employer/me', data: request.toJson());
  }
}
