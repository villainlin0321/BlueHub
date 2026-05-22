import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/auth/token_store.dart';
import '../../../features/auth/data/auth_models.dart';

class AuthService {
  AuthService({required ApiClient apiClient, required TokenStore tokenStore})
    : _apiClient = apiClient,
      _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  /// 使用邮箱登录信息换取登录态，并在成功后写入本地令牌。
  Future<LoginVO> emailLogin({required EmailLoginBO request}) async {
    final response = await _apiClient.post<LoginVO>(
      '/auth/email/login',
      data: request.toJson(),
      decode: (data) => LoginVO.fromJson(asJsonMap(data)),
    );
    if (response.accessToken.isNotEmpty) {
      _tokenStore.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }
    return response;
  }

  /// 向指定邮箱发送登录验证码。
  ///
  /// 返回值通常包含发送结果或冷却时间等整数字段。
  Future<Map<String, int>> sendEmailCode({required SendEmailBO request}) async {
    final response = await _apiClient.post<Map<String, int>>(
      '/auth/email/send',
      data: request.toJson(),
      decode: (data) => decodeMapValues<int>(
        data ?? const <String, dynamic>{},
        (value) => (value as num?)?.toInt() ?? 0,
      ),
    );
    return response;
  }

  /// 调用退出登录接口，并清空本地缓存的访问令牌与刷新令牌。
  Future<void> logout() async {
    await _apiClient.postVoid('/auth/logout');
    _tokenStore.clear();
  }

  /// 使用第三方 OAuth 凭证登录，并在成功后写入本地令牌。
  Future<LoginVO> oauthLogin({required OauthLoginBO request}) async {
    final response = await _apiClient.post<LoginVO>(
      '/auth/oauth/login',
      data: request.toJson(),
      decode: (data) => LoginVO.fromJson(asJsonMap(data)),
    );
    if (response.accessToken.isNotEmpty) {
      _tokenStore.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }
    return response;
  }

  /// 使用手机号验证码登录，并在成功后写入本地令牌。
  Future<LoginVO> phoneLogin({required PhoneLoginBO request}) async {
    final response = await _apiClient.post<LoginVO>(
      '/auth/phone/login',
      data: request.toJson(),
      decode: (data) => LoginVO.fromJson(asJsonMap(data)),
    );
    if (response.accessToken.isNotEmpty) {
      _tokenStore.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }
    return response;
  }

  /// 在登录流程中选择当前激活角色，并同步刷新本地令牌。
  Future<LoginVO> selectRole({required SelectRoleBO request}) async {
    final response = await _apiClient.post<LoginVO>(
      '/auth/select-role',
      data: request.toJson(),
      decode: (data) => LoginVO.fromJson(asJsonMap(data)),
    );
    if (response.accessToken.isNotEmpty) {
      _tokenStore.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }
    return response;
  }

  /// 向指定手机号发送短信验证码。
  ///
  /// 返回值通常包含发送结果或剩余冷却时间等整数字段。
  Future<Map<String, int>> sendSms({required SendSmsBO request}) async {
    final response = await _apiClient.post<Map<String, int>>(
      '/auth/sms/send',
      data: request.toJson(),
      decode: (data) => decodeMapValues<int>(
        data ?? const <String, dynamic>{},
        (value) => (value as num?)?.toInt() ?? 0,
      ),
    );
    return response;
  }

  /// 使用刷新令牌换取新的登录态，并覆盖本地缓存的令牌信息。
  Future<LoginVO> refreshToken({required RefreshTokenBO request}) async {
    final response = await _apiClient.post<LoginVO>(
      '/auth/token/refresh',
      data: request.toJson(),
      decode: (data) => LoginVO.fromJson(asJsonMap(data)),
    );
    if (response.accessToken.isNotEmpty) {
      _tokenStore.setTokens(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
      );
    }
    return response;
  }
}
