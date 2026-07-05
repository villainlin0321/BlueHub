import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// 求职者实名认证占位页：当前任务只承接路由落点，后续任务再补完整表单。
class JobSeekerRealNameVerificationPage extends StatelessWidget {
  const JobSeekerRealNameVerificationPage({super.key});

  @override
  /// 构建实名认证占位页，仅展示标题以验证入口和路由已打通。
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的.实名认证'.tr()),
      ),
      body: Center(
        child: Text(
          '我的.实名认证'.tr(),
        ),
      ),
    );
  }
}
