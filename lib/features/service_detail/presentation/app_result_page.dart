import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class AppResultPageArgs {
  const AppResultPageArgs({
    required this.pageTitle,
    required this.resultTitle,
    required this.tipText,
    required this.actionLabel,
    required this.action,
  });

  const AppResultPageArgs.paymentSuccess()
      : this(
          pageTitle: '支付结果',
          resultTitle: '支付成功',
          tipText: '可以在个人中心“订单管理”查看',
          actionLabel: '去上传提交材料',
          action: const AppResultAction.push(
            RoutePaths.myOrders,
          ),
        );

  final String pageTitle;
  final String resultTitle;
  final String tipText;
  final String actionLabel;
  final AppResultAction action;
}

class AppResultAction {
  const AppResultAction._({
    required this.type,
    this.route,
  });

  const AppResultAction.push(String route)
      : this._(
          type: AppResultActionType.push,
          route: route,
        );

  const AppResultAction.go(String route)
      : this._(
          type: AppResultActionType.go,
          route: route,
        );

  const AppResultAction.pop()
      : this._(type: AppResultActionType.pop);

  final AppResultActionType type;
  final String? route;
}

enum AppResultActionType {
  push,
  go,
  pop,
}

class AppResultPage extends StatelessWidget {
  const AppResultPage({
    super.key,
    this.args = const AppResultPageArgs.paymentSuccess(),
  });

  final AppResultPageArgs args;

  void _handleAction(BuildContext context) {
    switch (args.action.type) {
      case AppResultActionType.push:
        context.push(args.action.route!);
        return;
      case AppResultActionType.go:
        context.go(args.action.route!);
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
