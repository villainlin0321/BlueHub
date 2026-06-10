import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../order/presentation/order_detail_page.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class AppResultPageArgs {
  const AppResultPageArgs({
    required this.pageTitle,
    required this.resultTitle,
    required this.tipText,
    required this.actionLabel,
    required this.action,
    this.orderId,
  });

  factory AppResultPageArgs.paymentSuccess({int? orderId}) {
    return AppResultPageArgs(
      pageTitle: '服务详情.支付结果'.tr(),
      resultTitle: '服务详情.支付成功'.tr(),
      tipText: '服务详情.支付成功提示'.tr(),
      actionLabel: '服务详情.去上传提交材料'.tr(),
      action: const AppResultAction.push(RoutePaths.orderDetail),
      orderId: orderId,
    );
  }

  final String pageTitle;
  final String resultTitle;
  final String tipText;
  final String actionLabel;
  final AppResultAction action;
  final int? orderId;
}

class AppResultAction {
  const AppResultAction._({required this.type, this.route});

  const AppResultAction.push(String route)
    : this._(type: AppResultActionType.push, route: route);

  const AppResultAction.go(String route)
    : this._(type: AppResultActionType.go, route: route);

  const AppResultAction.pop() : this._(type: AppResultActionType.pop);

  final AppResultActionType type;
  final String? route;
}

enum AppResultActionType { push, go, pop }

class AppResultPage extends StatelessWidget {
  AppResultPage({super.key, AppResultPageArgs? args})
    : args = args ?? AppResultPageArgs.paymentSuccess();

  final AppResultPageArgs args;

  void _handleAction(BuildContext context) {
    final bool hasValidOrderId = (args.orderId ?? 0) > 0;
    switch (args.action.type) {
      case AppResultActionType.push:
        final String route =
            args.action.route == RoutePaths.orderDetail && !hasValidOrderId
            ? RoutePaths.myOrders
            : args.action.route!;
        context.pushReplacement(
          route,
          extra: route == RoutePaths.orderDetail
              ? OrderDetailPageArgs(orderId: args.orderId!)
              : null,
        );
        return;
      case AppResultActionType.go:
        final String route =
            args.action.route == RoutePaths.orderDetail && !hasValidOrderId
            ? RoutePaths.myOrders
            : args.action.route!;
        context.go(
          route,
          extra: route == RoutePaths.orderDetail
              ? OrderDetailPageArgs(orderId: args.orderId!)
              : null,
        );
        return;
      case AppResultActionType.pop:
        if (context.canPop()) {
          context.pop();
        }
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          args.pageTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 100),
              Image.asset(
                'assets/images/service_detail_payment_result_success.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              Text(
                args.resultTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                args.tipText,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF8C8C8C),
                  fontSize: 12,
                  height: 17 / 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 148,
                height: 36,
                child: FilledButton(
                  onPressed: () => _handleAction(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF096DD9),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    args.actionLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
