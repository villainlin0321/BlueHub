import 'package:europepass/shared/logging/app_log_scope.dart';

/// 单个日志字段允许保留的最大长度，避免详细日志无限膨胀。
const int defaultAppLogFieldMaxLength = 1500;

/// 日志级别：用于区分常规信息、告警和异常。
enum AppLogLevel { debug, info, warn, error, fatal }

/// 日志分层：用于区分应用、路由、交互、状态与网络等来源。
enum AppLogLayer { app, route, action, state, http }

/// 日志结果：用于描述一次事件最终状态。
enum AppLogResult { success, fail, skip, cancel, pending }

/// 结构化日志事件：统一承载层级、事件名、上下文和异常信息。
class AppLogEvent {
  /// 创建一条结构化日志事件。
  const AppLogEvent({
    required this.level,
    required this.layer,
    required this.event,
    required this.message,
    this.result,
    this.context,
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final AppLogLayer layer;
  final String event;
  final String message;
  final AppLogResult? result;
  final Map<String, Object?>? context;
  final Object? error;
  final StackTrace? stackTrace;

  /// 将结构化事件序列化为统一 JSON，并自动合并当前作用域上下文。
  Map<String, Object?> toJson() {
    final Map<String, Object?> mergedContext = AppLogScope.merge(context);
    return <String, Object?>{
      'time': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'layer': layer.name.toUpperCase(),
      'event': event,
      'message': message,
      if (result != null) 'result': result!.name,
      if (mergedContext.isNotEmpty)
        // 统一在序列化出口做脱敏和裁剪，确保控制台与文件端一致。
        'context': sanitizeAppLogValue(mergedContext) as Map<String, Object?>,
      if (error != null) 'error': truncateAppLogText(error.toString()),
      if (stackTrace != null)
        'stackTrace': truncateAppLogText(stackTrace.toString()),
    };
  }
}

/// 将日志上下文字段递归脱敏并裁剪超长文本，避免泄露敏感信息。
Object? sanitizeAppLogValue(
  Object? value, {
  String? key,
  int maxFieldLength = defaultAppLogFieldMaxLength,
}) {
  if (value == null) {
    return null;
  }

  if (value is Map) {
    return value.map((Object? currentKey, Object? currentValue) {
      final String normalizedKey = currentKey?.toString() ?? 'unknown';
      return MapEntry<String, Object?>(
        normalizedKey,
        sanitizeAppLogValue(
          currentValue,
          key: normalizedKey,
          maxFieldLength: maxFieldLength,
        ),
      );
    });
  }

  if (value is Iterable) {
    return value
        .map(
          (Object? item) => sanitizeAppLogValue(
            item,
            maxFieldLength: maxFieldLength,
          ),
        )
        .toList();
  }

  if (isSensitiveAppLogKey(key)) {
    return '***';
  }

  if (value is num || value is bool) {
    return value;
  }

  return truncateAppLogText(
    value.toString(),
    maxLength: maxFieldLength,
  );
}

/// 判断字段名是否命中敏感关键字。
bool isSensitiveAppLogKey(String? key) {
  if (key == null) {
    return false;
  }

  final String normalized = key.toLowerCase();
  return normalized.contains('token') ||
      normalized.contains('authorization') ||
      normalized.contains('password') ||
      normalized.contains('secret') ||
      // 统一把手机号和邮箱也纳入敏感字段规则，避免结构化快照明文落日志。
      normalized.contains('phone') ||
      normalized.contains('email') ||
      // 实名认证相关字段需要统一脱敏，避免身份证号或证件照片地址进入客户端日志。
      normalized.contains('realname') ||
      normalized.contains('idcard') ||
      normalized.contains('identitycard') ||
      key.contains('实名') ||
      key.contains('身份证');
}

/// 对超长日志文本做统一裁剪，保留前缀用于快速排障。
String truncateAppLogText(
  String text, {
  int maxLength = defaultAppLogFieldMaxLength,
}) {
  if (text.length <= maxLength) {
    return text;
  }

  return '${text.substring(0, maxLength)}...(truncated)';
}
