import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/data/home_providers.dart';
import '../../../shared/network/api_error_feedback.dart';
import '../data/application_models.dart';
import '../data/application_providers.dart';

/// 统一解析岗位投递失败文案，优先透传接口返回的真实错误信息。
String resolveJobApplyErrorMessage(Object error) {
  return ApiErrorFeedback.resolveMessage(error, fallback: '招聘.投递失败'.tr());
}

/// 统一提交岗位投递请求。
///
/// 返回 `null` 表示投递成功；返回字符串表示当前场景下应展示给用户的错误提示。
Future<String?> submitJobApplication(
  BuildContext context, {
  required int? jobId,
}) async {
  final ProviderContainer container = ProviderScope.containerOf(
    context,
    listen: false,
  );

  // 关键保护：没有真实岗位 ID 时，不发起无效请求，直接给出明确提示。
  if (jobId == null || jobId <= 0) {
    return '招聘.岗位信息缺失无法投递'.tr();
  }

  try {
    await container
        .read(applicationServiceProvider)
        .apply(request: CreateApplicationBO(jobId: jobId));

    // 投递成功后触发首页统计重新拉取，刷新失败不影响投递结果反馈。
    container.invalidate(homeDashboardStatsProvider);
    return null;
  } catch (error) {
    if (ApiErrorFeedback.hasAutoToast(error)) {
      return null;
    }
    return resolveJobApplyErrorMessage(error);
  }
}
