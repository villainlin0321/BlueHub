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

enum JobApplySubmissionStatus { success, failure, failureHandled }

/// 收口岗位投递结果，避免把“失败但已自动提示”误判为成功。
class JobApplySubmissionResult {
  const JobApplySubmissionResult._({
    required this.status,
    this.errorMessage,
  });

  const JobApplySubmissionResult.success()
    : this._(status: JobApplySubmissionStatus.success);

  const JobApplySubmissionResult.failure(String errorMessage)
    : this._(
        status: JobApplySubmissionStatus.failure,
        errorMessage: errorMessage,
      );

  const JobApplySubmissionResult.failureHandled()
    : this._(status: JobApplySubmissionStatus.failureHandled);

  final JobApplySubmissionStatus status;
  final String? errorMessage;

  bool get isSuccess => status == JobApplySubmissionStatus.success;
  bool get shouldShowError =>
      status == JobApplySubmissionStatus.failure &&
      errorMessage != null &&
      errorMessage!.trim().isNotEmpty;
}

/// 统一提交岗位投递请求。
///
/// 仅在真实投递成功时返回 `success`，避免把已自动提示的失败误判为成功。
Future<JobApplySubmissionResult> submitJobApplication(
  BuildContext context, {
  required int? jobId,
}) async {
  final ProviderContainer container = ProviderScope.containerOf(
    context,
    listen: false,
  );

  // 关键保护：没有真实岗位 ID 时，不发起无效请求，直接给出明确提示。
  if (jobId == null || jobId <= 0) {
    return JobApplySubmissionResult.failure('招聘.岗位信息缺失无法投递'.tr());
  }

  try {
    await container
        .read(applicationServiceProvider)
        .apply(request: CreateApplicationBO(jobId: jobId));

    // 投递成功后触发首页统计重新拉取，刷新失败不影响投递结果反馈。
    container.invalidate(homeDashboardStatsProvider);
    return const JobApplySubmissionResult.success();
  } catch (error) {
    if (ApiErrorFeedback.hasAutoToast(error)) {
      return const JobApplySubmissionResult.failureHandled();
    }
    return JobApplySubmissionResult.failure(resolveJobApplyErrorMessage(error));
  }
}
