import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/me/data/user_models.dart';

class UserService {
  UserService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> deleteAccount({String? reason}) async {
    final queryParameters = <String, dynamic>{
      if (reason != null) 'reason': reason,
    };
    return _apiClient.deleteVoid(
      '/users/me',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  Future<UserVO> getMe() async {
    final response = await _apiClient.get<UserVO>(
      '/users/me',
      decode: (data) => UserVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<void> updateMe({required UpdateUserBO request}) async {
    return _apiClient.putVoid('/users/me', data: request.toJson());
  }

  Future<PageResult<UserVO>> getBlacklist({int? page, int? pageSize}) async {
    final queryParameters = <String, dynamic>{
      if (page != null) 'page': page,
      if (pageSize != null) 'page_size': pageSize,
    };
    final response = await _apiClient.get<PageResult<UserVO>>(
      '/users/me/blacklist',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      decode: (data) => PageResult<UserVO>.fromJson(
        asJsonMap(data),
        fromJson: UserVO.fromJson,
      ),
    );
    return response;
  }

  Future<void> manageBlacklist({required BlacklistBO request}) async {
    return _apiClient.postVoid('/users/me/blacklist', data: request.toJson());
  }

  Future<void> registerDeviceToken({required DeviceTokenBO request}) async {
    return _apiClient.postVoid(
      '/users/me/device-token',
      data: request.toJson(),
    );
  }

  Future<void> realNameVerify({required RealNameVerifyBO request}) async {
    return _apiClient.postVoid(
      '/users/me/real-name-verify',
      data: request.toJson(),
    );
  }

  Future<void> switchRole({required SwitchRoleBO request}) async {
    return _apiClient.putVoid('/users/me/role', data: request.toJson());
  }
}
