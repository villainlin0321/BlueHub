import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_svg_icon.dart';

class ServiceDetailPaymentResultPage extends StatelessWidget {
  const ServiceDetailPaymentResultPage({super.key});

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
          '支付结果',
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
                '支付成功',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontSize: 16,
                  height: 22 / 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '可以在个人中心“订单管理”查看',
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
                  onPressed: () {},
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF096DD9),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    '去上传提交材料',
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
