import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/order/application/payment/payment_flow_coordinator.dart';
import 'package:europepass/features/order/data/payment_providers.dart';
import 'package:europepass/features/order/presentation/order_payment_bottom_sheet.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/payment_service.dart';

/// Widget 测试入口
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('支付弹层打开和确认支付会输出关键交互日志', (WidgetTester tester) async {
    final FakeLogRecorder recorder = FakeLogRecorder();
    try {
      await tester.pumpWidget(
        TestOrderPaymentHost(
          logRecorder: recorder,
          orderId: 9001,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('立即支付'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('确认支付').last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(
        recorder.events.any(
          (FakeLogEvent event) => event.event == 'ORDER_PAYMENT_SHEET_OPEN',
        ),
        isTrue,
      );
      expect(
        recorder.events.any(
          (FakeLogEvent event) => event.event == 'ORDER_PAYMENT_CONFIRM_TAP',
        ),
        isTrue,
      );
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
    required this.logRecorder,
    required this.orderId,
  });

  final FakeLogRecorder logRecorder;
  final int orderId;

  @override
  State<TestOrderPaymentHost> createState() => _TestOrderPaymentHostState();
}

class _TestOrderPaymentHostState extends State<TestOrderPaymentHost> {
  @override
  void initState() {
    super.initState();
    widget.logRecorder.attach();
  }

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      fallbackLocale: AppLocales.english,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      useOnlyLangCode: true,
      child: ProviderScope(
        overrides: [
          paymentFlowCoordinatorProvider.overrideWithValue(
            _FakePaymentFlowCoordinator(),
          ),
        ],
        child: MaterialApp(
          builder: EasyLoading.init(),
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () {
                      // 直接复用真实弹层入口，确保测试覆盖真实交互链路。
                      OrderPaymentBottomSheet.show(
                        context: context,
                        amount: 199,
                        currency: 'EUR',
                        orderId: widget.orderId,
                        packageName: '测试套餐',
                        parentContext: context,
                      );
                    },
                    child: const Text('立即支付'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// 控制台日志记录器：拦截 PrettyPrinter 输出并按事件名回放关键交互日志。
class FakeLogRecorder {
  final List<String> _consoleLines = <String>[];
  void Function(String?, {int? wrapWidth})? _originalDebugPrint;

  /// 开始拦截控制台日志，供测试断言结构化事件名。
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

  /// 当前已捕获到的结构化日志事件列表。
  List<FakeLogEvent> get events {
    final String consoleText = _consoleLines.join('\n');
    return RegExp(r'"event": "([^"]+)"')
        .allMatches(consoleText)
        .map((RegExpMatch match) => FakeLogEvent(event: match.group(1)!))
        .toList(growable: false);
  }

  /// 结束日志拦截，避免影响后续测试。
  void dispose() {
    final void Function(String?, {int? wrapWidth})? originalDebugPrint =
        _originalDebugPrint;
    if (originalDebugPrint == null) {
      return;
    }
    debugPrint = originalDebugPrint;
    _originalDebugPrint = null;
  }
}

/// 测试用日志事件：仅保留事件名即可完成本轮高价值断言。
class FakeLogEvent {
  const FakeLogEvent({required this.event});

  final String event;
}

/// 支付流程替身：阻断真实网络与跳转，仅保留交互日志触发所需的最小行为。
class _FakePaymentFlowCoordinator extends PaymentFlowCoordinator {
  _FakePaymentFlowCoordinator()
    : super(paymentService: _UnusedPaymentService());

  @override
  Future<PaymentFlowResult> startPayment({
    required int orderId,
    required AppPaymentMethod method,
  }) async {
    return const PaymentFlowResult(
      status: PaymentFlowStatus.failed,
      message: '测试支付已拦截',
    );
  }
}

/// 未被实际调用的支付服务占位实现，仅用于满足父类构造函数依赖。
class _UnusedPaymentService extends PaymentService {
  _UnusedPaymentService() : super(apiClient: ApiClient(Dio()));
}
