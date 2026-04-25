import '../../../shared/auth/token_store.dart';
import '../../../shared/network/api_client.dart';
import 'login_models.dart';

class AuthService {
  AuthService({
    required ApiClient apiClient,
    required TokenStore tokenStore,
  })  : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  Future<LoginResponse> phoneLogin({
    required String phone,
    required String countryCode,
    required String code,
  }) async {
    final req = PhoneLoginRequest(phone: phone, countryCode: countryCode, code: code);
    final res = await _apiClient.post<LoginResponse>(
      '/auth/phone/login',
      data: req.toJson(),
      decode: (data) => LoginResponse.fromJson((data as Map).cast<String, dynamic>()),
    );

    if (res.accessToken.isNotEmpty) {
      _tokenStore.setTokens(accessToken: res.accessToken, refreshToken: res.refreshToken);
    }

    return res;
  }
}

