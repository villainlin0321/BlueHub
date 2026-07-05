import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/order/data/visa_order_models.dart';
import 'package:europepass/features/order/data/visa_order_providers.dart';
import 'package:europepass/features/order/presentation/order_management_page.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/services/visa_order_service.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('已完成和已取消订单不展示处理订单按钮', (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: [
        visaOrderServiceProvider.overrideWithValue(
          _FakeVisaOrderService(
            orders: <VisaOrderVO>[
              _buildFakeOrder(status: 'completed', statusLabel: '已完成', orderId: 1),
              _buildFakeOrder(status: 'cancelled', statusLabel: '已取消', orderId: 2),
              _buildFakeOrder(status: 'reviewing', statusLabel: '审核中', orderId: 3),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(_buildTestHost(container: container));
    await tester.pumpAndSettle();

    expect(find.text('处理订单'), findsOneWidget);
    expect(find.text('联系客户'), findsNWidgets(3));
  });
}

/// 构建带本地化与 Riverpod 注入能力的最小测试宿主。
Widget _buildTestHost({required ProviderContainer container}) {
  return UncontrolledProviderScope(
    container: container,
    child: EasyLocalization(
      supportedLocales: AppLocales.supported,
      path: 'assets/translations',
      assetLoader: const _TestJsonFileAssetLoader(),
      fallbackLocale: AppLocales.chinese,
      startLocale: AppLocales.chinese,
      saveLocale: false,
      child: Builder(
        builder: (BuildContext context) {
          return MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: const OrderManagementPage(),
          );
        },
      ),
    ),
  );
}

/// 测试环境直接读取仓库翻译文件，避免 widget test 无法加载 assets。
class _TestJsonFileAssetLoader extends AssetLoader {
  const _TestJsonFileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final File file = File('${Directory.current.path}/$path/${locale.languageCode}.json');
    final String content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}

/// 提供固定订单列表的假服务，避免测试依赖真实网络。
class _FakeVisaOrderService extends VisaOrderService {
  _FakeVisaOrderService({required this.orders}) : super(apiClient: ApiClient(Dio()));

  final List<VisaOrderVO> orders;

  @override
  Future<PageResult<VisaOrderVO>> listProviderOrders({
    int? page,
    int? pageSize,
    String? status,
    String? country,
  }) async {
    return PageResult<VisaOrderVO>(
      list: orders,
      pagination: Pagination(
        page: 1,
        total: orders.length,
        pageSize: orders.length,
        totalPages: 1,
        hasNext: false,
      ),
    );
  }
}

/// 构造页面渲染所需的最小订单数据，聚焦验证按钮显隐行为。
VisaOrderVO _buildFakeOrder({
  required int orderId,
  required String status,
  required String statusLabel,
}) {
  return VisaOrderVO.fromJson(<String, dynamic>{
    'orderId': orderId,
    'orderNo': 'NO-$orderId',
    'status': status,
    'statusLabel': statusLabel,
    'currentStep': 2,
    'steps': const <Map<String, dynamic>>[],
    'amount': 99.0,
    'currency': 'EUR',
    'packageName': '测试服务',
    'tierName': '标准档',
    'providerName': '测试服务商',
    'packageInfo': <String, dynamic>{
      'packageName': '测试服务',
      'tierName': '标准档',
      'amount': 99.0,
      'currency': 'EUR',
    },
    'providerInfo': <String, dynamic>{'providerId': 10, 'name': '测试服务商'},
    'requiredMaterials': const <Map<String, dynamic>>[],
    'materials': const <Map<String, dynamic>>[],
    'visaDocuments': const <Map<String, dynamic>>[],
    'applicant': <String, dynamic>{
      'userId': 1000 + orderId,
      'nickname': '客户$orderId',
      'avatarUrl': '',
      'type': 'worker',
      'profileId': 2000 + orderId,
    },
    'rejectReason': null,
    'latestReject': null,
    'isUrgent': false,
    'country': 'DE',
    'createdAt': '2026-07-05T10:00:00Z',
    'updatedAt': '2026-07-05T12:00:00Z',
    'paymentUrl': null,
  });
}
