import 'package:flutter/material.dart';

import 'visa_package_detail_scaffold.dart';

class VisaPackagePreviewPageArgs {
  const VisaPackagePreviewPageArgs({required this.packageId, this.providerId});

  final int packageId;
  final int? providerId;
}

/// 服务商发布后的签证套餐预览页，仅保留浏览能力。
class VisaPackagePreviewPage extends StatelessWidget {
  const VisaPackagePreviewPage({super.key, required this.args});

  final VisaPackagePreviewPageArgs args;

  @override
  Widget build(BuildContext context) {
    return VisaPackageDetailScaffold(
      args: VisaPackageDetailScaffoldArgs(
        packageId: args.packageId,
        providerId: args.providerId,
        mode: VisaPackageDetailMode.preview,
      ),
    );
  }
}
