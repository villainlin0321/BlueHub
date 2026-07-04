import 'dart:async';

typedef AppLogFields = Map<String, Object?>;

/// 日志作用域：为同一条异步链路提供可继承的上下文字段。
class AppLogScope {
  static const Symbol _zoneKey = #appLogScopeFields;

  /// 返回当前异步链路已经继承的作用域字段快照。
  static AppLogFields get current {
    final Object? value = Zone.current[_zoneKey];
    if (value is Map<String, Object?>) {
      return Map<String, Object?>.from(value);
    }
    return <String, Object?>{};
  }

  /// 在指定上下文中执行动作，让 sessionId、traceId 等字段自动沿异步链路传播。
  static T run<T>({
    String? sessionId,
    String? traceId,
    AppLogFields fields = const <String, Object?>{},
    required T Function() action,
  }) {
    final Map<String, Object?> next = <String, Object?>{
      ...current,
      if (sessionId != null) 'sessionId': sessionId,
      if (traceId != null) 'traceId': traceId,
      ...fields,
    };

    // 使用 Zone 保存链路上下文，避免并发异步流程之间互相污染。
    return runZoned<T>(action, zoneValues: <Object?, Object?>{_zoneKey: next});
  }

  /// 合并当前作用域与本次日志字段，后者优先级更高。
  static AppLogFields merge(AppLogFields? fields) {
    final Map<String, Object?> merged = current;
    if (fields != null) {
      merged.addAll(fields);
    }
    return merged;
  }
}
