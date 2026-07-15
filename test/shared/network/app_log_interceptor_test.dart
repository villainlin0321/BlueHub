import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/network/interceptors/app_log_interceptor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证 AppLogInterceptor 会复用 HTTP 链路字段，并把敏感字段交给统一日志出口递归脱敏。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  late Directory tempDirectory;

  /// 读取当前日志文件中的结构化日志，便于直接断言真实输出内容。
  Future<List<Map<String, Object?>>> readJsonLogEntries() async {
    final String? content = await AppLogger.instance.readCurrentLog();
    if (content == null || content.trim().isEmpty) {
      return <Map<String, Object?>>[];
    }

    return content
        .split('\n')
        .where((String line) => line.trim().isNotEmpty)
        .map((String line) {
          final Object? decoded = jsonDecode(line);
          return Map<String, Object?>.from(decoded! as Map<dynamic, dynamic>);
        })
        .toList();
  }

  /// 读取原始日志文本，确保敏感字段不会以明文形式落盘。
  Future<String> readRawLogContent() async {
    return await AppLogger.instance.readCurrentLog() ?? '';
  }

  /// 等待异步日志写入完成，避免测试读取到未刷盘的中间状态。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  /// 将结构化日志里的上下文安全转换为 `Map`，便于断言嵌套字段。
  Map<String, Object?> readContext(Map<String, Object?> entry) {
    return Map<String, Object?>.from(entry['context']! as Map);
  }

  /// 将任意嵌套对象转换为 `Map`，用于读取请求体与响应体快照。
  Map<String, Object?> readNestedMap(Object? value) {
    return Map<String, Object?>.from(value! as Map);
  }

  /// 将任意嵌套对象转换为列表，便于断言数组中的敏感字段。
  List<Object?> readNestedList(Object? value) {
    return List<Object?>.from(value! as List);
  }

  setUpAll(() async {
    tempDirectory = await Directory.systemTemp.createTemp(
      'bluehub_app_log_interceptor_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return tempDirectory.path;
          }
          return tempDirectory.path;
        });
    await AppLogger.instance.init();
    await waitForLogFlush();
  });

  tearDownAll(() async {
    await AppLogger.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('AppLogInterceptor 会把 traceId、route 和业务动作写入请求上下文', () {
    final options = RequestOptions(path: '/jobs');

    AppLogScope.run(
      traceId: 'trace-post-job',
      fields: const <String, Object?>{
        'route': '/jobs/post',
        'action': 'POST_JOB_SUBMIT_TAP',
      },
      action: () {
        final interceptor = AppLogInterceptor(enabled: true);
        interceptor.onRequest(options, RequestInterceptorHandler());
      },
    );

    expect(options.extra['traceId'], 'trace-post-job');
    expect(options.extra['route'], '/jobs/post');
    expect(options.extra['logAction'], 'POST_JOB_SUBMIT_TAP');
  });

  test('requestStart 到 requestFail 会复用同一条 traceId route action 链路', () async {
    const traceId = 'trace-fail-chain';
    const route = '/jobs/post';
    const action = 'POST_JOB_SUBMIT_CONFIRM';
    final interceptor = AppLogInterceptor(enabled: true);
    final options = RequestOptions(path: '/jobs', method: 'POST');

    AppLogScope.run(
      traceId: traceId,
      fields: const <String, Object?>{
        'route': route,
        'action': action,
      },
      action: () {
        interceptor.onRequest(options, RequestInterceptorHandler());
      },
    );

    interceptor.onError(
      DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 500,
          data: const <String, Object?>{'reason': 'server error'},
        ),
        type: DioExceptionType.badResponse,
        message: 'server exploded',
      ),
      _SilentErrorInterceptorHandler(),
    );
    await waitForLogFlush();

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries
        .where(
          (Map<String, Object?> item) =>
              (item['context'] as Map<String, Object?>?)?['traceId'] ==
                  traceId &&
              (item['event'] == 'HTTP_REQUEST_START' ||
                  item['event'] == 'HTTP_REQUEST_FAIL'),
        )
        .toList();

    expect(matchedEntries, hasLength(2));
    final Map<String, Object?> startContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) => item['event'] == 'HTTP_REQUEST_START',
      ),
    );
    final Map<String, Object?> failContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) => item['event'] == 'HTTP_REQUEST_FAIL',
      ),
    );

    // 关键断言：失败链路必须复用首条请求日志写入的同一组链路字段。
    expect(startContext['requestId'], failContext['requestId']);
    expect(startContext['traceId'], traceId);
    expect(failContext['traceId'], traceId);
    expect(startContext['route'], route);
    expect(failContext['route'], route);
    expect(startContext['action'], action);
    expect(failContext['action'], action);
  });

  test('敏感字段不会因请求体或失败响应被预序列化而明文落日志', () async {
    const traceId = 'trace-sensitive-http';
    const email = 'debugger@example.com';
    const phone = '+8613800138000';
    const password = 'P@ssw0rd-For-Test';
    const accessToken = 'token-should-never-appear';
    const realName = '张三';
    const idCardNumber = '110101199003047777';
    const idCardFrontUrl = 'https://example.com/id-card-portrait.png';
    const idCardBackUrl = 'https://example.com/id-card-emblem.png';
    final interceptor = AppLogInterceptor(enabled: true);
    final options = RequestOptions(
      path: '/profile',
      method: 'POST',
      data: <String, Object?>{
        'profile': <String, Object?>{
          'email': email,
          'phone': phone,
        },
        'realName': realName,
        'idCardNumber': idCardNumber,
        'idCardFrontUrl': idCardFrontUrl,
        'idCardBackUrl': idCardBackUrl,
        'password': password,
        'tokens': <Object?>[
          <String, Object?>{'accessToken': accessToken},
        ],
      },
    );

    AppLogScope.run(
      traceId: traceId,
      fields: const <String, Object?>{
        'route': '/profile/edit',
        'action': 'PROFILE_SUBMIT_TAP',
      },
      action: () {
        interceptor.onRequest(options, RequestInterceptorHandler());
      },
    );

    interceptor.onError(
      DioException(
        requestOptions: options,
        response: Response<Object?>(
          requestOptions: options,
          statusCode: 401,
          data: <String, Object?>{
            'token': accessToken,
            'idCardNumber': idCardNumber,
            'idCardFrontUrl': idCardFrontUrl,
            'user': <String, Object?>{
              'realName': realName,
              'email': email,
              'phone': phone,
            },
          },
        ),
        type: DioExceptionType.badResponse,
        message: 'unauthorized',
      ),
      _SilentErrorInterceptorHandler(),
    );
    await waitForLogFlush();

    final String rawLogContent = await readRawLogContent();
    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final Map<String, Object?> startContext = readContext(
      entries.lastWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'HTTP_REQUEST_START' &&
            (item['context'] as Map<String, Object?>?)?['traceId'] == traceId,
      ),
    );
    final Map<String, Object?> failContext = readContext(
      entries.lastWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'HTTP_REQUEST_FAIL' &&
            (item['context'] as Map<String, Object?>?)?['traceId'] == traceId,
      ),
    );
    final Map<String, Object?> requestBody = readNestedMap(startContext['body']);
    final Map<String, Object?> requestProfile = readNestedMap(
      requestBody['profile'],
    );
    final List<Object?> requestTokens = readNestedList(requestBody['tokens']);
    final Map<String, Object?> requestTokenItem = readNestedMap(
      requestTokens.single,
    );
    final Map<String, Object?> responseBody = readNestedMap(failContext['response']);
    final Map<String, Object?> responseUser = readNestedMap(responseBody['user']);

    // 关键断言：body/response 仍然保持结构化对象，统一脱敏出口才能按键递归处理。
    expect(startContext['body'], isA<Map>());
    expect(failContext['response'], isA<Map>());
    expect(requestProfile['email'], '***');
    expect(requestProfile['phone'], '***');
    expect(requestBody['realName'], '***');
    expect(requestBody['idCardNumber'], '***');
    expect(requestBody['idCardFrontUrl'], '***');
    expect(requestBody['idCardBackUrl'], '***');
    expect(requestBody['password'], '***');
    expect(requestTokenItem['accessToken'], '***');
    expect(responseBody['token'], '***');
    expect(responseBody['idCardNumber'], '***');
    expect(responseBody['idCardFrontUrl'], '***');
    expect(responseUser['realName'], '***');
    expect(responseUser['email'], '***');
    expect(responseUser['phone'], '***');
    expect(rawLogContent, isNot(contains(realName)));
    expect(rawLogContent, isNot(contains(idCardNumber)));
    expect(rawLogContent, isNot(contains(idCardFrontUrl)));
    expect(rawLogContent, isNot(contains(idCardBackUrl)));
    expect(rawLogContent, isNot(contains(email)));
    expect(rawLogContent, isNot(contains(phone)));
    expect(rawLogContent, isNot(contains(password)));
    expect(rawLogContent, isNot(contains(accessToken)));
  });
}

/// 吞掉测试里的 Dio 错误续传，避免 `handler.next(err)` 变成未捕获异步异常。
class _SilentErrorInterceptorHandler extends ErrorInterceptorHandler {
  @override
  /// 测试只关心拦截器产生日志，不需要继续把错误抛给后续拦截器。
  void next(DioException error) {}

  @override
  /// 测试场景不会走到 resolve，显式留空以保持 handler 行为可控。
  void resolve(Response<dynamic> response) {}

  @override
  /// 测试场景不会走到 reject，显式留空以保持 handler 行为可控。
  void reject(DioException error) {}
}
