import 'package:dio/dio.dart';
import 'package:europepass/features/auth/data/auth_models.dart';
import 'package:europepass/shared/auth/token_store.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('邮箱验证码登录时空密码不会写入请求体', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient();
    final AuthService service = AuthService(
      apiClient: apiClient,
      tokenStore: TokenStore.inMemory(),
    );

    await service.emailLogin(
      request: const EmailLoginBO(
        email: 'user@example.com',
        password: '',
        code: '123456',
      ),
    );

    expect(apiClient.lastPath, '/auth/email/login');
    expect(apiClient.lastData, isA<Map<String, dynamic>>());
    expect(apiClient.lastData, <String, dynamic>{
      'email': 'user@example.com',
      'code': '123456',
    });
  });

  test('邮箱验证码登录时 null 密码不会写入请求体', () async {
    final _RecordingApiClient apiClient = _RecordingApiClient();
    final AuthService service = AuthService(
      apiClient: apiClient,
      tokenStore: TokenStore.inMemory(),
    );

    await service.emailLogin(
      request: const _NullablePasswordEmailLoginBO(
        email: 'user@example.com',
        code: '123456',
      ),
    );

    expect(apiClient.lastData, isA<Map<String, dynamic>>());
    expect(apiClient.lastData, <String, dynamic>{
      'email': 'user@example.com',
      'code': '123456',
    });
  });
}

class _RecordingApiClient extends ApiClient {
  _RecordingApiClient() : super(Dio());

  String? lastPath;
  Object? lastData;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic data) decode,
    Options? options,
  }) async {
    lastPath = path;
    lastData = data;
    return LoginVO(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          expiresIn: 3600,
          isNewUser: false,
          needSelectRole: false,
          user: const UserSimpleVO(
            userId: 1,
            phone: '',
            countryCode: '+86',
            role: 'job_seeker',
            avatarUrl: '',
            nickname: 'tester',
            email: 'user@example.com',
          ),
        )
        as T;
  }
}

class _NullablePasswordEmailLoginBO extends EmailLoginBO {
  const _NullablePasswordEmailLoginBO({
    required super.email,
    required super.code,
  }) : super(password: '');

  @override
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'email': email, 'password': null, 'code': code};
  }
}
