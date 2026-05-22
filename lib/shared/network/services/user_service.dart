import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/page_result.dart';
import '../../../features/me/data/user_models.dart';

class UserService {
  UserService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// 注销当前登录账号。
  ///
  /// 可选传入 `reason` 作为注销原因，便于后端留档。
  Future<void> deleteAccount({String? reason}) async {
    final queryParameters = <String, dynamic>{
      if (reason != null) 'reason': reason,
    };
    return _apiClient.deleteVoid(
      '/users/me',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
  }

  /// 获取当前登录用户的个人信息。
  Future<UserVO> getMe() async {
    final response = await _apiClient.get<UserVO>(
      '/users/me',
      decode: (data) => UserVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  /// 更新当前登录用户的个人资料。
  Future<void> updateMe({required UpdateUserBO request}) async {
    return _apiClient.putVoid('/users/me', data: request.toJson());
  }

  /// 分页获取当前用户的黑名单列表。
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

  /// 新增或移除黑名单对象。
  ///
  /// 具体动作由 `request` 中的业务字段控制。
  Future<void> manageBlacklist({required BlacklistBO request}) async {
    return _apiClient.postVoid('/users/me/blacklist', data: request.toJson());
  }

  /// 登记当前设备的推送令牌。
  ///
  /// 用于消息推送或系统通知的设备绑定。
  Future<void> registerDeviceToken({required DeviceTokenBO request}) async {
    return _apiClient.postVoid(
      '/users/me/device-token',
      data: request.toJson(),
    );
  }

  /// 提交当前用户的实名认证信息。
  Future<void> realNameVerify({required RealNameVerifyBO request}) async {
    return _apiClient.postVoid(
      '/users/me/real-name-verify',
      data: request.toJson(),
    );
  }

  /// 切换当前登录用户的激活角色。
  Future<void> switchRole({required SwitchRoleBO request}) async {
    return _apiClient.putVoid('/users/me/role', data: request.toJson());
  }
}
