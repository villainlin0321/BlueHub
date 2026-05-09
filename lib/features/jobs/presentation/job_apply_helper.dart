import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_exception.dart';
import '../data/application_models.dart';
import '../data/application_providers.dart';

/// 统一解析岗位投递失败文案，优先透传接口返回的真实错误信息。
String resolveJobApplyErrorMessage(Object error) {
  if (error is ApiException) {
    return error.message;
  }
  return '投递失败，请稍后重试';
}

/// 统一提交岗位投递请求。
///
/// 返回 `null` 表示投递成功；返回字符串表示当前场景下应展示给用户的错误提示。
Future<String?> submitJobApplication(
  BuildContext context, {
  required int? jobId,
}) async {
  // 关键保护：没有真实岗位 ID 时，不发起无效请求，直接给出明确提示。
  if (jobId == null || jobId <= 0) {
    return '岗位信息缺失，暂无法投递';
  }

  try {
    await ProviderScope.containerOf(
      context,
      listen: false,
    ).read(applicationServiceProvider).apply(
      request: CreateApplicationBO(jobId: jobId),
    );
    return null;
  } catch (error) {
    return resolveJobApplyErrorMessage(error);
  }
}
