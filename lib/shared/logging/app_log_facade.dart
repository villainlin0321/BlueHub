import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:europepass/shared/logging/app_log_scope.dart';
import 'package:europepass/shared/logging/app_logger.dart';
import 'package:europepass/shared/logging/app_route_tracker.dart';

typedef AppLogContext = Map<String, Object?>;

/// 统一生成链路追踪 ID，供动作、HTTP 和业务事件串联使用。
String buildAppTraceId([String prefix = 'trace']) {
  return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
}

/// 应用流程日志门面：负责启动、生命周期和宿主级事件。
class AppFlowLog {
  AppFlowLog._();

  /// 记录一条应用层结构化日志。
  static void log({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitStructuredLog(
      level: level,
      layer: AppLogLayer.app,
      event: event,
      message: message,
      result: result,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录应用生命周期切换，统一沉淀到 APP 分层日志。
  static void lifecycle({
    required String state,
    String message = '应用生命周期已变化',
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
  }) {
    log(
      event: 'APP_LIFECYCLE',
      message: message,
      level: level,
      result: result,
      context: <String, Object?>{
        'state': state,
        if (context != null) ...context,
      },
    );
  }

  /// 记录应用启动开始事件，统一补齐启动链路的起点字段。
  static void bootstrapStart({AppLogContext? context}) {
    log(
      event: 'APP_BOOTSTRAP_START',
      message: '应用启动流程开始',
      result: AppLogResult.pending,
      context: context,
    );
  }

  /// 记录应用启动成功事件，便于回放初始化流程何时完成。
  static void bootstrapSuccess({AppLogContext? context}) {
    log(
      event: 'APP_BOOTSTRAP_SUCCESS',
      message: '应用启动流程完成',
      result: AppLogResult.success,
      context: context,
    );
  }

  /// 记录应用启动失败事件，并保留排障所需的错误上下文。
  static void bootstrapFail({
    required Object error,
    StackTrace? stackTrace,
    AppLogContext? context,
  }) {
    log(
      event: 'APP_BOOTSTRAP_FAIL',
      message: '应用启动流程失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// 路由日志门面：负责页面进入、退出和重定向等事件。
class RouteLog {
  RouteLog._();

  /// 记录一条路由层结构化日志。
  static void log({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitStructuredLog(
      level: level,
      layer: AppLogLayer.route,
      event: event,
      message: message,
      result: result,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录页面进入事件，便于回放真实跳转结果。
  static void enter({
    required String route,
    String? from,
    AppLogContext? context,
  }) {
    log(
      event: 'ROUTE_ENTER',
      message: '进入页面',
      context: <String, Object?>{
        'route': route,
        if (from != null) 'from': from,
        if (context != null) ...context,
      },
    );
  }

  /// 记录页面退出事件，便于查看离开前后页面关系。
  static void exit({
    required String route,
    String? to,
    AppLogContext? context,
  }) {
    log(
      event: 'ROUTE_EXIT',
      message: '退出页面',
      context: <String, Object?>{
        'route': route,
        if (to != null) 'to': to,
        if (context != null) ...context,
      },
    );
  }

  /// 记录路由重定向事件，突出守卫决策和目标页面。
  static void redirect({
    required String from,
    required String to,
    required String reason,
    AppLogLevel level = AppLogLevel.warn,
    AppLogContext? context,
  }) {
    log(
      event: 'ROUTE_REDIRECT',
      message: '路由已重定向',
      level: level,
      result: AppLogResult.success,
      context: <String, Object?>{
        'from': from,
        'to': to,
        'reason': reason,
        if (context != null) ...context,
      },
    );
  }

  /// 记录已生效的路由重定向，突出原始地址、目标地址和触发原因。
  static void redirectApplied({
    required String from,
    required String to,
    required String reason,
    AppLogLevel level = AppLogLevel.warn,
    AppLogContext? context,
  }) {
    log(
      event: 'ROUTE_REDIRECT_APPLIED',
      message: '路由重定向已生效',
      level: level,
      result: AppLogResult.success,
      context: <String, Object?>{
        'from': from,
        'to': to,
        'reason': reason,
        if (context != null) ...context,
      },
    );
  }
}

/// 交互日志门面：为后续页面动作和用户操作补点提供统一入口。
class ActionLog {
  ActionLog._();

  /// 记录一条交互层结构化日志。
  static void log({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitStructuredLog(
      level: level,
      layer: AppLogLayer.action,
      event: event,
      message: message,
      result: result,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 在一次用户动作范围内注入 traceId，让后续异步日志自动继承链路上下文。
  static T run<T>({
    required String event,
    required String message,
    AppLogContext? fields,
    String? traceId,
    required T Function() action,
  }) {
    final resolvedTraceId = traceId ?? buildAppTraceId('action');
    return AppLogScope.run<T>(
      traceId: resolvedTraceId,
      fields: fields ?? const <String, Object?>{},
      action: () {
        log(event: event, message: message, result: AppLogResult.pending);
        return action();
      },
    );
  }

  /// 记录点击类交互事件，统一补齐交互类型，避免各页面重复拼接 `actionType`。
  static void tap({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
  }) {
    log(
      event: event,
      message: message,
      level: level,
      result: result,
      context: <String, Object?>{
        'actionType': 'tap',
        if (context != null) ...context,
      },
    );
  }

  /// 记录弹层打开事件，统一保留交互类型，便于和点击、关闭等事件区分。
  static void sheetOpen({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
  }) {
    log(
      event: event,
      message: message,
      level: level,
      result: result,
      context: <String, Object?>{
        'actionType': 'sheet_open',
        if (context != null) ...context,
      },
    );
  }

  /// 记录列表滚动到底的交互事件，统一补齐交互类型与页面滚动语义。
  static void scrollReachEnd({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
  }) {
    log(
      event: event,
      message: message,
      level: level,
      result: result,
      context: <String, Object?>{
        'actionType': 'scroll_reach_end',
        if (context != null) ...context,
      },
    );
  }
}

/// 状态日志门面：负责 Provider 与 Controller 等状态链路的统一记录。
class StateLog {
  StateLog._();

  /// 记录一条状态层结构化日志。
  static void log({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitStructuredLog(
      level: level,
      layer: AppLogLayer.state,
      event: event,
      message: message,
      result: result,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录高价值 Provider 的状态变化，保留前后快照和触发来源。
  static void providerChanged({
    required String provider,
    Object? previousValue,
    Object? newValue,
    AppLogContext? context,
  }) {
    log(
      event: 'PROVIDER_UPDATED',
      message: 'Provider 状态已变化',
      context: <String, Object?>{
        'provider': provider,
        // 统一把原始快照交给日志出口做脱敏与裁剪，避免这里过早退化成纯文本。
        if (previousValue != null) 'previous': previousValue,
        if (newValue != null) 'next': newValue,
        if (context != null) ...context,
      },
    );
  }

  /// 记录 Provider 失败事件，便于快速定位状态链路中的异常来源。
  static void providerFailed({
    required String provider,
    required Object error,
    required StackTrace stackTrace,
    AppLogContext? context,
  }) {
    log(
      event: 'PROVIDER_FAILED',
      message: 'Provider 执行失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      context: <String, Object?>{
        'provider': provider,
        if (context != null) ...context,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录状态链路中的关键阶段切换，便于按事件名回放开始、成功和失败过程。
  static void transition({
    required String event,
    required String message,
    String? from,
    String? to,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      event: event,
      message: message,
      level: level,
      result: result,
      context: <String, Object?>{
        if (from != null) 'from': from,
        if (to != null) 'to': to,
        if (context != null) ...context,
      },
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录页面或流程中的单步状态事件，适合页面进入等离散节点日志。
  static void step({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    log(
      event: event,
      message: message,
      level: level,
      result: result,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// 网络日志门面：为后续请求与业务动作串联提供统一出口。
class HttpFlowLog {
  HttpFlowLog._();

  /// 记录一条网络层结构化日志。
  static void log({
    required String event,
    required String message,
    AppLogLevel level = AppLogLevel.info,
    AppLogResult? result,
    AppLogContext? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitStructuredLog(
      level: level,
      layer: AppLogLayer.http,
      event: event,
      message: message,
      result: result,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// 记录 HTTP 请求发起事件，并串联请求基础信息与链路字段。
  static void requestStart({
    required String requestId,
    required String method,
    required String uri,
    Map<String, Object?>? context,
  }) {
    log(
      event: 'HTTP_REQUEST_START',
      message: '发起请求',
      result: AppLogResult.pending,
      context: <String, Object?>{
        'requestId': requestId,
        'method': method,
        'uri': uri,
        if (context != null) ...context,
      },
    );
  }

  /// 记录 HTTP 请求成功事件，便于和请求开始、失败日志完整回放。
  static void requestSuccess({
    required String requestId,
    required String method,
    required String uri,
    int? statusCode,
    int? durationMs,
    Map<String, Object?>? context,
  }) {
    log(
      event: 'HTTP_REQUEST_SUCCESS',
      message: '请求成功',
      result: AppLogResult.success,
      context: <String, Object?>{
        'requestId': requestId,
        'method': method,
        'uri': uri,
        if (statusCode != null) 'statusCode': statusCode,
        if (durationMs != null) 'durationMs': durationMs,
        if (context != null) ...context,
      },
    );
  }

  /// 记录 HTTP 请求失败事件，统一沉淀异常类型、状态码和链路上下文。
  static void requestFail({
    required String requestId,
    required String method,
    required String uri,
    required Object error,
    StackTrace? stackTrace,
    String? errorType,
    int? statusCode,
    int? durationMs,
    Map<String, Object?>? context,
  }) {
    log(
      event: 'HTTP_REQUEST_FAIL',
      message: '请求失败',
      level: AppLogLevel.error,
      result: AppLogResult.fail,
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        'requestId': requestId,
        'method': method,
        'uri': uri,
        if (errorType != null) 'type': errorType,
        if (statusCode != null) 'statusCode': statusCode,
        if (durationMs != null) 'durationMs': durationMs,
        if (context != null) ...context,
      },
    );
  }
}

/// 统一补齐当前路由上下文后输出结构化事件，避免各层手工重复拼字段。
void _emitStructuredLog({
  required AppLogLevel level,
  required AppLogLayer layer,
  required String event,
  required String message,
  AppLogResult? result,
  AppLogContext? context,
  Object? error,
  StackTrace? stackTrace,
}) {
  final normalizedContext = _normalizeContext(context);
  AppLogger.instance.logEvent(
    AppLogEvent(
      level: level,
      layer: layer,
      event: event,
      message: message,
      result: result,
      context: normalizedContext.isEmpty ? null : normalizedContext,
      error: error,
      stackTrace: stackTrace,
    ),
  );
}

/// 合并显式上下文与当前路由，确保 HTTP/状态/交互日志自动带上页面信息。
AppLogContext _normalizeContext(AppLogContext? context) {
  final AppLogContext normalizedContext = <String, Object?>{
    if (context != null) ...context,
  };
  final currentRoute = AppRouteTracker.instance.currentRoute;
  if (currentRoute != null &&
      currentRoute.isNotEmpty &&
      !normalizedContext.containsKey('route')) {
    normalizedContext['route'] = currentRoute;
  }
  return normalizedContext;
}
