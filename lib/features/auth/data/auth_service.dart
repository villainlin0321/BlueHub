import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/auth/token_store.dart';
import 'auth_models.dart';

class AuthService {
  AuthService({required ApiClient apiClient, required TokenStore tokenStore})
    : _apiClient = apiClient,
      _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

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

  Future<void> logout() async {
    await _apiClient.postVoid('/auth/logout');
    _tokenStore.clear();
  }

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
