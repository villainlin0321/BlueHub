import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'visa_package_detail_scaffold.dart';

class ServiceDetailPageArgs {
  const ServiceDetailPageArgs({
    required this.packageId,
    this.providerId,
    this.initialIsCollected = false,
  });

  final int packageId;
  final int? providerId;
  final bool initialIsCollected;
}

/// 普通签证服务详情页，沿用完整业务交互。
class ServiceDetailPage extends StatelessWidget {
  const ServiceDetailPage({super.key, this.args});

  final ServiceDetailPageArgs? args;

  @override
  Widget build(BuildContext context) {
    final ServiceDetailPageArgs? resolvedArgs = args;
    if (resolvedArgs == null) {
      return Scaffold(body: Center(child: Text('服务详情.缺少套餐参数'.tr())));
    }
    return VisaPackageDetailScaffold(
      args: VisaPackageDetailScaffoldArgs(
        packageId: resolvedArgs.packageId,
        providerId: resolvedArgs.providerId,
        initialIsCollected: resolvedArgs.initialIsCollected,
      ),
    );
  }
}
