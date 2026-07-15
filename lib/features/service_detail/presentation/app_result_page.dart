import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/test_keys.dart';
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
    this.backAction = const AppResultAction.pop(),
    this.countdownSeconds,
    this.countdownAction,
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
  final AppResultAction backAction;
  final int? countdownSeconds;
  final AppResultAction? countdownAction;
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

class AppResultPage extends StatefulWidget {
  AppResultPage({super.key, AppResultPageArgs? args})
    : args = args ?? AppResultPageArgs.paymentSuccess();

  final AppResultPageArgs args;

  @override
  State<AppResultPage> createState() => _AppResultPageState();
}

class _AppResultPageState extends State<AppResultPage> {
  Timer? _countdownTimer;
  late int _remainingSeconds;
  bool _hasHandledCountdownAction = false;

  AppResultPageArgs get args => widget.args;

  bool get _hasCountdown =>
      (args.countdownSeconds ?? 0) > 0 && args.countdownAction != null;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = args.countdownSeconds ?? 0;
    _startCountdownIfNeeded();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// 当结果页配置了倒计时时，启动每秒递减的计时器，并在结束后自动执行目标动作。
  void _startCountdownIfNeeded() {
    if (!_hasCountdown) {
      return;
    }
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _remainingSeconds = 0;
        _handleCountdownAction();
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  /// 统一处理倒计时结束后的自动跳转，避免定时器与手动点击重复触发。
  void _handleCountdownAction() {
    if (_hasHandledCountdownAction || !_hasCountdown || !mounted) {
      return;
    }
    _hasHandledCountdownAction = true;
    _handleAction(context, args.countdownAction!);
  }

  /// 统一处理结果页动作，保证主按钮与左上角返回都走同一套路由分发逻辑。
  void _handleAction(BuildContext context, AppResultAction action) {
    _countdownTimer?.cancel();
    _hasHandledCountdownAction = true;
    final bool hasValidOrderId = (args.orderId ?? 0) > 0;
    switch (action.type) {
      case AppResultActionType.push:
        final String route =
            action.route == RoutePaths.orderDetail && !hasValidOrderId
            ? RoutePaths.myOrders
            : action.route!;
        context.pushReplacement(
          route,
          extra: route == RoutePaths.orderDetail
              ? OrderDetailPageArgs(orderId: args.orderId!)
              : null,
        );
        return;
      case AppResultActionType.go:
        final String route =
            action.route == RoutePaths.orderDetail && !hasValidOrderId
            ? RoutePaths.myOrders
            : action.route!;
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

  /// 统一构造结果页提示文案，在需要时仅替换原文中的秒数字段，保持单行展示。
  String _buildTipText() {
    if (!_hasCountdown) {
      return args.tipText;
    }
    return args.tipText.replaceFirst(
      RegExp(r'\d+s后进入首页'),
      '${_remainingSeconds}s后进入首页',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: AppTestKeys.pageQualificationCertificationResult,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => _handleAction(context, args.backAction),
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
                _buildTipText(),
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
                  onPressed: () => _handleAction(context, args.action),
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
