import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/order/application/payment/payment_flow_coordinator.dart';
import 'package:europepass/features/order/data/payment_providers.dart';
import 'package:europepass/features/order/presentation/order_payment_bottom_sheet.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/payment_service.dart';

/// Widget 测试入口。
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('支付弹层切换支付方式并关闭时会输出结构化事件', (WidgetTester tester) async {
    final FakeStructuredLogRecorder recorder = FakeStructuredLogRecorder();
    final _FakePaymentFlowCoordinator coordinator = _FakePaymentFlowCoordinator();
    recorder.attach();
    try {
      await tester.pumpWidget(
        TestOrderPaymentHost(orderId: 9001, coordinator: coordinator),
      );
      await tester.pumpAndSettle();
      await tester.state<_TestOrderPaymentHostState>(
        find.byType(TestOrderPaymentHost),
      ).showPaymentSheet();
      await tester.pumpAndSettle();

      // 文案必须展示可读文本，不能把 key 原样回退到界面。
      expect(find.text('确认支付'), findsWidgets);
      expect(find.text('订单支付.确认支付'), findsNothing);
      expect(find.text('服务详情.确认支付'), findsNothing);

      await tester.tap(find.text('微信支付').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      final List<Map<String, Object?>> matchedEntries = recorder.events.where((
        Map<String, Object?> item,
      ) {
        final Map<String, Object?>? context =
            item['context'] == null
                ? null
                : Map<String, Object?>.from(item['context']! as Map);
        return context?['orderId'] == '9001' &&
            (item['event'] == 'ORDER_PAYMENT_SHEET_OPEN' ||
                item['event'] == 'ORDER_PAYMENT_METHOD_SWITCH' ||
                item['event'] == 'ORDER_PAYMENT_SHEET_CLOSE');
      }).toList();

      final Map<String, Object?> openContext = Map<String, Object?>.from(
        matchedEntries.firstWhere(
          (Map<String, Object?> item) =>
              item['event'] == 'ORDER_PAYMENT_SHEET_OPEN',
        )['context']! as Map,
      );
      final Map<String, Object?> switchContext = Map<String, Object?>.from(
        matchedEntries.firstWhere(
          (Map<String, Object?> item) =>
              item['event'] == 'ORDER_PAYMENT_METHOD_SWITCH',
        )['context']! as Map,
      );
      final Map<String, Object?> closeContext = Map<String, Object?>.from(
        matchedEntries.firstWhere(
          (Map<String, Object?> item) =>
              item['event'] == 'ORDER_PAYMENT_SHEET_CLOSE',
        )['context']! as Map,
      );

      // 打开、切换和关闭必须落在同一条链路，方便回放整段用户交互。
      expect(openContext['traceId'], isNotEmpty);
      expect(openContext['traceId'], switchContext['traceId']);
      expect(openContext['traceId'], closeContext['traceId']);
      expect(switchContext['paymentMethod'], 'wechat_pay');
      expect(switchContext['previousPaymentMethod'], 'alipay');
      expect(closeContext['closeReason'], 'close_button');
      expect(coordinator.calls, isEmpty);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      recorder.dispose();
    }
  });

  testWidgets('微信支付确认支付必须走协调器以保持日志链路完整', (WidgetTester tester) async {
    final FakeStructuredLogRecorder recorder = FakeStructuredLogRecorder();
    final _FakePaymentFlowCoordinator coordinator = _FakePaymentFlowCoordinator();
    recorder.attach();
    try {
      await tester.pumpWidget(
        TestOrderPaymentHost(orderId: 9002, coordinator: coordinator),
      );
      await tester.pumpAndSettle();
      await tester.state<_TestOrderPaymentHostState>(
        find.byType(TestOrderPaymentHost),
      ).showPaymentSheet();
      await tester.pumpAndSettle();

      await tester.tap(find.text('微信支付').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('确认支付').last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(coordinator.calls, hasLength(1));
      expect(coordinator.calls.single.orderId, 9002);
      expect(coordinator.calls.single.method, AppPaymentMethod.wechat);

      final List<Map<String, Object?>> matchedEntries = recorder.events.where((
        Map<String, Object?> item,
      ) {
        final Map<String, Object?>? context =
            item['context'] == null
                ? null
                : Map<String, Object?>.from(item['context']! as Map);
        return context?['orderId'] == '9002' &&
            (item['event'] == 'ORDER_PAYMENT_METHOD_SWITCH' ||
                item['event'] == 'ORDER_PAYMENT_CONFIRM_TAP');
      }).toList();
      final Map<String, Object?> switchContext = Map<String, Object?>.from(
        matchedEntries.firstWhere(
          (Map<String, Object?> item) =>
              item['event'] == 'ORDER_PAYMENT_METHOD_SWITCH',
        )['context']! as Map,
      );
      final Map<String, Object?> confirmContext = Map<String, Object?>.from(
        matchedEntries.firstWhere(
          (Map<String, Object?> item) =>
              item['event'] == 'ORDER_PAYMENT_CONFIRM_TAP',
        )['context']! as Map,
      );
      expect(confirmContext['traceId'], switchContext['traceId']);
      expect(confirmContext['paymentMethod'], 'wechat_pay');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      recorder.dispose();
    }
  });
}

/// 支付弹层测试宿主：提供最小可点击入口，并注入可控的支付流程替身。
class TestOrderPaymentHost extends StatefulWidget {
  const TestOrderPaymentHost({
    super.key,
    required this.orderId,
    required this.coordinator,
  });

  final int orderId;
  final PaymentFlowCoordinator coordinator;

  @override
  State<TestOrderPaymentHost> createState() => _TestOrderPaymentHostState();
}

class _TestOrderPaymentHostState extends State<TestOrderPaymentHost> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// 通过真实页面上下文拉起支付弹层，确保测试覆盖生产入口而不是替身包装。
  Future<void> showPaymentSheet() async {
    final BuildContext? sheetContext = _navigatorKey.currentContext;
    if (sheetContext == null) {
      throw StateError('sheet context is not ready');
    }
    OrderPaymentBottomSheet.show(
      context: sheetContext,
      amount: 199,
      currency: 'EUR',
      orderId: widget.orderId,
      packageName: '测试套餐',
      parentContext: sheetContext,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        paymentFlowCoordinatorProvider.overrideWithValue(
          widget.coordinator,
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        locale: AppLocales.chinese,
        supportedLocales: AppLocales.supported,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: EasyLoading.init(),
        home: const Scaffold(body: SizedBox.expand()),
      ),
    );
  }
}

/// 控制台结构化日志记录器：从 PrettyPrinter 多行输出里还原单条 JSON 载荷。
class FakeStructuredLogRecorder {
  final List<String> _consoleLines = <String>[];
  void Function(String?, {int? wrapWidth})? _originalDebugPrint;

  /// 开始拦截控制台日志，供测试直接断言交互事件与 traceId。
  void attach() {
    if (_originalDebugPrint != null) {
      return;
    }
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) {
        _consoleLines.add(message);
      }
      _originalDebugPrint?.call(message, wrapWidth: wrapWidth);
    };
  }

  /// 还原当前已捕获到的结构化日志事件列表。
  List<Map<String, Object?>> get events {
    final List<Map<String, Object?>> parsed = <Map<String, Object?>>[];
    final List<String> jsonLines = <String>[];
    int braceBalance = 0;
    bool capturing = false;

    for (final String line in _consoleLines) {
      if (!capturing && line.startsWith('│ {')) {
        capturing = true;
        jsonLines.clear();
        final String content = line.substring(2);
        jsonLines.add(content);
        braceBalance = _countBraceDelta(content);
        if (braceBalance == 0) {
          _tryParseEvent(parsed, jsonLines);
          capturing = false;
        }
        continue;
      }

      if (!capturing || !line.startsWith('│ ')) {
        continue;
      }

      final String content = line.substring(2);
      jsonLines.add(content);
      braceBalance += _countBraceDelta(content);
      if (braceBalance == 0) {
        _tryParseEvent(parsed, jsonLines);
        capturing = false;
      }
    }

    return parsed;
  }

  /// 恢复默认控制台输出，避免污染后续测试。
  void dispose() {
    final void Function(String?, {int? wrapWidth})? originalDebugPrint =
        _originalDebugPrint;
    if (originalDebugPrint == null) {
      return;
    }
    debugPrint = originalDebugPrint;
    _originalDebugPrint = null;
  }

  /// 统计当前行的大括号增减量，用于识别一条 JSON 何时结束。
  int _countBraceDelta(String line) {
    return '{'.allMatches(line).length - '}'.allMatches(line).length;
  }

  /// 尝试把一段 PrettyPrinter 的 JSON 文本还原成 Map，失败时静默忽略非结构化输出。
  void _tryParseEvent(
    List<Map<String, Object?>> parsed,
    List<String> jsonLines,
  ) {
    try {
      final Object? decoded = jsonDecode(jsonLines.join('\n'));
      if (decoded is Map) {
        parsed.add(Map<String, Object?>.from(decoded));
      }
    } catch (_) {
      // 非 JSON 控制台输出不参与本轮结构化断言。
    }
  }
}

/// 支付流程替身：记录调用参数并阻断真实网络与跳转。
class _FakePaymentFlowCoordinator extends PaymentFlowCoordinator {
  _FakePaymentFlowCoordinator()
    : super(paymentService: _UnusedPaymentService());

  final List<_PaymentCall> calls = <_PaymentCall>[];

  @override
  /// 记录调用参数，供测试断言不同支付方式是否统一收口到协调器。
  Future<PaymentFlowResult> startPayment({
    required int orderId,
    required AppPaymentMethod method,
  }) async {
    calls.add(_PaymentCall(orderId: orderId, method: method));
    return const PaymentFlowResult(
      status: PaymentFlowStatus.failed,
      message: '测试支付已拦截',
    );
  }
}

/// 记录单次支付协调器调用参数，便于断言是否真的走了统一入口。
class _PaymentCall {
  const _PaymentCall({required this.orderId, required this.method});

  final int orderId;
  final AppPaymentMethod method;
}

/// 未被实际调用的支付服务占位实现，仅用于满足父类构造函数依赖。
class _UnusedPaymentService extends PaymentService {
  _UnusedPaymentService() : super(apiClient: ApiClient(Dio()));
}
