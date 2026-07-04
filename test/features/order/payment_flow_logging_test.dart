import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/order/application/payment/payment_flow_coordinator.dart';
import 'package:europepass/features/order/data/payment_models.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/payment_service.dart';
import 'package:europepass/shared/payment/payment_channel_config.dart';
import 'package:europepass/shared/payment/payment_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 验证支付创建、拉起和轮询链路会输出可回放日志，并继续遵守统一脱敏规则。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel pathProviderChannel = MethodChannel(
    'plugins.flutter.io/path_provider',
  );
  Directory? tempDirectory;

  /// 读取当前日志文件中的结构化日志，便于断言事件名和上下文字段。
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

  /// 读取日志原文，确保敏感支付串不会被明文写入本地文件。
  Future<String> readRawLogContent() async {
    return await AppLogger.instance.readCurrentLog() ?? '';
  }

  /// 等待异步日志刷盘，避免测试读取到中间状态。
  Future<void> waitForLogFlush() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  /// 从结构化日志中安全读取上下文字段。
  Map<String, Object?> readContext(Map<String, Object?> entry) {
    return Map<String, Object?>.from(entry['context']! as Map);
  }

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
    tempDirectory = await Directory.systemTemp.createTemp(
      'bluehub_payment_flow_logging_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (
          MethodCall methodCall,
        ) async {
          switch (methodCall.method) {
            case 'getApplicationSupportDirectory':
            case 'getApplicationDocumentsDirectory':
              return tempDirectory!.path;
          }
          return tempDirectory!.path;
        });
    await AppLogger.instance.init();
    await waitForLogFlush();
  });

  tearDownAll(() async {
    await AppLogger.instance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    final Directory? currentTempDirectory = tempDirectory;
    if (currentTempDirectory != null && await currentTempDirectory.exists()) {
      await currentTempDirectory.delete(recursive: true);
    }
  });

  test('startPayment 会记录创建、拉起和轮询结果日志', () async {
    final PaymentFlowCoordinator coordinator = PaymentFlowCoordinator(
      paymentService: _FakePaymentService.success(),
      paymentLauncher: const _FakePaymentLauncher.success(),
    );

    final PaymentFlowResult result = await coordinator.startPayment(
      orderId: 1001,
      method: AppPaymentMethod.alipay,
    );
    await waitForLogFlush();

    expect(result.status, PaymentFlowStatus.success);

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries.where((
      Map<String, Object?> item,
    ) {
      final Map<String, Object?>? context =
          item['context'] == null ? null : readContext(item);
      return context?['orderId'] == '1001' &&
          (item['event'] == 'PAYMENT_CREATE_START' ||
              item['event'] == 'PAYMENT_CREATE_SUCCESS' ||
              item['event'] == 'PAYMENT_LAUNCH_SUCCESS' ||
              item['event'] == 'PAYMENT_STATUS_POLL_SUCCESS');
    }).toList();

    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'PAYMENT_CREATE_START';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'PAYMENT_LAUNCH_SUCCESS';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'PAYMENT_STATUS_POLL_SUCCESS';
      }),
      isTrue,
    );

    final Map<String, Object?> createContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) => item['event'] == 'PAYMENT_CREATE_START',
      ),
    );
    final Map<String, Object?> launchContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) => item['event'] == 'PAYMENT_LAUNCH_SUCCESS',
      ),
    );
    final Map<String, Object?> pollContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'PAYMENT_STATUS_POLL_SUCCESS',
      ),
    );

    // 关键断言：三段事件必须复用同一条 traceId，并保留关键订单上下文。
    expect(createContext['traceId'], isNotEmpty);
    expect(createContext['traceId'], launchContext['traceId']);
    expect(createContext['traceId'], pollContext['traceId']);
    expect(createContext['orderId'], '1001');
    expect(launchContext['paymentMethod'], 'alipay');
    expect(pollContext['paymentStatus'], 'success');

    final String rawLogContent = await readRawLogContent();
    expect(rawLogContent, isNot(contains('alipay-order-sensitive-token')));
  });

  test('startPayment 在拉起待确认时也会进入轮询并串联 traceId 日志', () async {
    final PaymentFlowCoordinator coordinator = PaymentFlowCoordinator(
      paymentService: _FakePaymentService.pendingThenSuccess(),
      paymentLauncher: const _FakePaymentLauncher.pending(),
    );

    final PaymentFlowResult result = await coordinator.startPayment(
      orderId: 1002,
      method: AppPaymentMethod.alipay,
    );
    await waitForLogFlush();

    expect(result.status, PaymentFlowStatus.success);

    final List<Map<String, Object?>> entries = await readJsonLogEntries();
    final List<Map<String, Object?>> matchedEntries = entries.where((
      Map<String, Object?> item,
    ) {
      final Map<String, Object?>? context =
          item['context'] == null ? null : readContext(item);
      return context?['orderId'] == '1002' &&
          (item['event'] == 'PAYMENT_CREATE_START' ||
              item['event'] == 'PAYMENT_LAUNCH_PENDING' ||
              item['event'] == 'PAYMENT_STATUS_POLL_PENDING' ||
              item['event'] == 'PAYMENT_STATUS_POLL_SUCCESS');
    }).toList();

    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'PAYMENT_LAUNCH_PENDING';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'PAYMENT_STATUS_POLL_PENDING';
      }),
      isTrue,
    );
    expect(
      matchedEntries.any((Map<String, Object?> item) {
        return item['event'] == 'PAYMENT_STATUS_POLL_SUCCESS';
      }),
      isTrue,
    );

    final Map<String, Object?> createContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) => item['event'] == 'PAYMENT_CREATE_START',
      ),
    );
    final Map<String, Object?> launchPendingContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) => item['event'] == 'PAYMENT_LAUNCH_PENDING',
      ),
    );
    final Map<String, Object?> pollPendingContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'PAYMENT_STATUS_POLL_PENDING',
      ),
    );
    final Map<String, Object?> pollSuccessContext = readContext(
      matchedEntries.firstWhere(
        (Map<String, Object?> item) =>
            item['event'] == 'PAYMENT_STATUS_POLL_SUCCESS',
      ),
    );

    // 关键断言：待确认分支也必须完整串起创建、拉起、轮询的同一条 traceId。
    expect(createContext['traceId'], isNotEmpty);
    expect(createContext['traceId'], launchPendingContext['traceId']);
    expect(createContext['traceId'], pollPendingContext['traceId']);
    expect(createContext['traceId'], pollSuccessContext['traceId']);
    expect(launchPendingContext['launchStatus'], 'pending');
    expect(pollPendingContext['paymentStatus'], 'processing');
    expect(pollPendingContext['attempt'], '1');
    expect(pollSuccessContext['paymentStatus'], 'success');
    expect(pollSuccessContext['attempt'], '2');

    final String rawLogContent = await readRawLogContent();
    expect(rawLogContent, isNot(contains('alipay-order-sensitive-token')));
  });
}

/// 提供可控的支付服务替身，避免测试依赖真实网络与接口返回。
class _FakePaymentService extends PaymentService {
  _FakePaymentService._({
    required this.paymentResult,
    required this.paymentStatuses,
  }) : super(apiClient: ApiClient(Dio()));

  final PaymentResultVO paymentResult;
  final List<PaymentStatusVO> paymentStatuses;
  int _statusIndex = 0;

  /// 构造一个创建成功且轮询直接成功的支付服务替身。
  factory _FakePaymentService.success() {
    return _FakePaymentService._(
      paymentResult: const PaymentResultVO(
        paymentId: 91,
        paymentMethod: 'alipay',
        outTradeNo: 'TRADE202607050001',
        wxPartnerId: null,
        wxPrepayId: null,
        wxPackageValue: null,
        wxNonceStr: null,
        wxTimestamp: null,
        wxSign: null,
        alipayOrderString: 'alipay-order-sensitive-token',
      ),
      paymentStatuses: const <PaymentStatusVO>[
        PaymentStatusVO(
          paymentId: 91,
          orderId: 1001,
          paymentMethod: 'alipay',
          amount: 99.0,
          status: 'success',
          paidAt: '2026-07-05T00:00:00Z',
        ),
      ],
    );
  }

  /// 构造一个先返回处理中、再返回成功的支付服务替身，覆盖待确认轮询链路。
  factory _FakePaymentService.pendingThenSuccess() {
    return _FakePaymentService._(
      paymentResult: const PaymentResultVO(
        paymentId: 92,
        paymentMethod: 'alipay',
        outTradeNo: 'TRADE202607050002',
        wxPartnerId: null,
        wxPrepayId: null,
        wxPackageValue: null,
        wxNonceStr: null,
        wxTimestamp: null,
        wxSign: null,
        alipayOrderString: 'alipay-order-sensitive-token',
      ),
      paymentStatuses: const <PaymentStatusVO>[
        PaymentStatusVO(
          paymentId: 92,
          orderId: 1002,
          paymentMethod: 'alipay',
          amount: 199.0,
          status: 'processing',
          paidAt: null,
        ),
        PaymentStatusVO(
          paymentId: 92,
          orderId: 1002,
          paymentMethod: 'alipay',
          amount: 199.0,
          status: 'success',
          paidAt: '2026-07-05T00:05:00Z',
        ),
      ],
    );
  }

  @override
  /// 返回预设的支付创建结果，模拟支付单创建成功。
  Future<PaymentResultVO> createPayment({
    required CreatePaymentBO request,
  }) async {
    return paymentResult;
  }

  @override
  /// 按顺序返回预设状态，模拟支付轮询结果。
  Future<PaymentStatusVO> queryPaymentStatus({required int orderId}) async {
    final int safeIndex = _statusIndex.clamp(0, paymentStatuses.length - 1);
    final PaymentStatusVO next = paymentStatuses[safeIndex];
    if (_statusIndex < paymentStatuses.length - 1) {
      _statusIndex += 1;
    }
    return next;
  }
}

/// 提供可控的支付拉起器替身，避免测试依赖真实支付 SDK。
class _FakePaymentLauncher implements PaymentLauncher {
  const _FakePaymentLauncher.success()
    : _result = const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.success,
        message: '支付宝拉起成功',
      );

  const _FakePaymentLauncher.pending()
    : _result = const AppPaymentLaunchResult(
        status: AppPaymentLaunchStatus.pending,
        message: '支付宝结果待确认',
      );

  final AppPaymentLaunchResult _result;

  @override
  /// 测试场景不需要真实初始化支付 SDK，这里保持空实现。
  Future<void> initialize({PaymentChannelConfig? config}) async {}

  @override
  /// 返回预设的支付宝拉起结果，模拟 SDK 拉起成功。
  Future<AppPaymentLaunchResult> payWithAlipay(PaymentResultVO payload) async {
    return _result;
  }

  @override
  /// 当前测试只覆盖支付宝链路，微信支付若被误调用则直接失败。
  Future<AppPaymentLaunchResult> payWithWeChat(PaymentResultVO payload) async {
    throw UnimplementedError('test only covers alipay flow');
  }
}
