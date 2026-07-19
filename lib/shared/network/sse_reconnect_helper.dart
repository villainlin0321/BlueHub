import 'dart:async';

import '../logging/app_logger.dart';

/// 单次建连工厂，返回一个新的 SSE 事件流。
typedef SseStreamFactory<T> = Stream<T> Function();

/// 表示 SSE 流在达到最大重连次数后已进入熔断状态。
class SseReconnectCircuitOpenException implements Exception {
  const SseReconnectCircuitOpenException({
    required this.streamName,
    required this.attempts,
  });

  /// 当前熔断的流名称，用于日志与错误提示定位。
  final String streamName;

  /// 进入熔断前已使用的连续重连次数。
  final int attempts;

  @override
  String toString() {
    return 'SseReconnectCircuitOpenException('
        'streamName: $streamName, attempts: $attempts'
        ')';
  }
}

/// 为 SSE 流提供统一的断线重连与熔断能力。
///
/// - 正常结束和异常结束都会触发重连；
/// - 采用指数退避，默认最多连续重连 10 次；
/// - 任意一次成功收到事件后，会把连续失败计数清零；
/// - 达到上限后向外抛出熔断异常，并关闭流。
class SseReconnectHelper<T> {
  const SseReconnectHelper({
    required this.streamFactory,
    required this.logTag,
    required this.streamName,
    this.maxReconnectAttempts = 10,
    this.initialReconnectDelay = const Duration(seconds: 1),
    this.maxReconnectDelay = const Duration(seconds: 10),
  }) : assert(maxReconnectAttempts > 0, 'maxReconnectAttempts 必须大于 0');

  /// 返回新的底层 SSE 流的工厂方法。
  final SseStreamFactory<T> streamFactory;

  /// 输出日志时使用的标签。
  final String logTag;

  /// 人类可读的流名称，用于日志描述。
  final String streamName;

  /// 连续失败后的最大重连次数。
  final int maxReconnectAttempts;

  /// 第一次重连等待时长。
  final Duration initialReconnectDelay;

  /// 指数退避的最大等待时长。
  final Duration maxReconnectDelay;

  /// 创建带自动重连能力的包装流。
  Stream<T> connect() {
    late final StreamController<T> controller;
    StreamSubscription<T>? innerSubscription;
    Timer? reconnectTimer;
    late Future<void> Function() startListening;
    late Future<void> Function({
      required String reason,
      Object? error,
      StackTrace? stackTrace,
    }) scheduleReconnect;
    bool isClosedByConsumer = false;
    bool isConnecting = false;
    bool hasReceivedEventInCurrentConnection = false;
    int consecutiveReconnectFailures = 0;

    Duration resolveReconnectDelay(int attempt) {
      final int multiplier = 1 << (attempt - 1);
      final int delayMs = initialReconnectDelay.inMilliseconds * multiplier;
      final int cappedMs = delayMs > maxReconnectDelay.inMilliseconds
          ? maxReconnectDelay.inMilliseconds
          : delayMs;
      return Duration(milliseconds: cappedMs);
    }

    Future<void> disposeInnerSubscription() async {
      final StreamSubscription<T>? currentSubscription = innerSubscription;
      innerSubscription = null;
      if (currentSubscription == null) {
        return;
      }
      await currentSubscription.cancel();
    }

    scheduleReconnect = ({
      required String reason,
      Object? error,
      StackTrace? stackTrace,
    }) async {
      await disposeInnerSubscription();
      if (isClosedByConsumer || controller.isClosed) {
        return;
      }

      reconnectTimer?.cancel();
      final int nextAttempt = consecutiveReconnectFailures + 1;
      if (nextAttempt > maxReconnectAttempts) {
        final SseReconnectCircuitOpenException exception =
            SseReconnectCircuitOpenException(
              streamName: streamName,
              attempts: consecutiveReconnectFailures,
            );
        AppLogger.instance.error(
          logTag,
          '$streamName 连续重连失败，已触发熔断',
          error: error ?? exception,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'reason': reason,
            'maxReconnectAttempts': maxReconnectAttempts,
          },
        );
        controller.addError(exception, stackTrace ?? StackTrace.current);
        unawaited(controller.close());
        return;
      }

      consecutiveReconnectFailures = nextAttempt;
      final Duration delay = resolveReconnectDelay(consecutiveReconnectFailures);
      AppLogger.instance.warn(
        logTag,
        '$streamName 已断开，准备发起重连',
        context: <String, Object?>{
          'reason': reason,
          'attempt': consecutiveReconnectFailures,
          'maxReconnectAttempts': maxReconnectAttempts,
          'delayMs': delay.inMilliseconds,
        },
      );
      reconnectTimer = Timer(delay, () {
        reconnectTimer = null;
        unawaited(startListening());
      });
    };

    startListening = () async {
      if (isClosedByConsumer || controller.isClosed || isConnecting) {
        return;
      }
      isConnecting = true;
      hasReceivedEventInCurrentConnection = false;
      try {
        innerSubscription = streamFactory().listen(
          (T event) {
            if (isClosedByConsumer || controller.isClosed) {
              return;
            }
            if (!hasReceivedEventInCurrentConnection) {
              hasReceivedEventInCurrentConnection = true;
              if (consecutiveReconnectFailures > 0) {
                AppLogger.instance.info(
                  logTag,
                  '$streamName 重连恢复成功',
                  context: <String, Object?>{
                    'reconnectAttemptsUsed': consecutiveReconnectFailures,
                  },
                );
              }
              consecutiveReconnectFailures = 0;
            }
            controller.add(event);
          },
          onError: (Object error, StackTrace stackTrace) {
            unawaited(
              scheduleReconnect(
                reason: 'error',
                error: error,
                stackTrace: stackTrace,
              ),
            );
          },
          onDone: () {
            unawaited(scheduleReconnect(reason: 'done'));
          },
          cancelOnError: false,
        );
      } catch (error, stackTrace) {
        await scheduleReconnect(
          reason: 'connect_throw',
          error: error,
          stackTrace: stackTrace,
        );
      } finally {
        isConnecting = false;
      }
    };

    controller = StreamController<T>(
      onListen: () {
        unawaited(startListening());
      },
      onCancel: () async {
        isClosedByConsumer = true;
        reconnectTimer?.cancel();
        reconnectTimer = null;
        await disposeInnerSubscription();
      },
    );
    return controller.stream;
  }
}
