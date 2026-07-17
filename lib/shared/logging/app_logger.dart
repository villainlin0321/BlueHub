import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:europepass/shared/logging/app_log_event.dart';
import 'package:logger/logger.dart' as logger;
import 'package:path_provider/path_provider.dart';

/// 全局日志类：统一负责控制台输出、本地文件落盘和日志文件读取。
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const int _maxLogFiles = 7;
  static const Duration _debugFlushInterval = Duration(seconds: 2);
  static const Duration _releaseFlushInterval = Duration(seconds: 8);
  static const int _debugFlushLineThreshold = 10;
  static const int _releaseFlushLineThreshold = 30;
  IOSink? _sink;
  File? _currentLogFile;
  Future<void>? _initTask;
  Future<void> _writeQueue = Future<void>.value();
  final List<String> _pendingFileLines = <String>[];
  Timer? _flushTimer;
  bool _isFlushing = false;
  late final logger.Logger _logger = logger.Logger(
    printer: logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 100,
      colors: false,
      printEmojis: false,
      dateTimeFormat: logger.DateTimeFormat.onlyTimeAndSinceStart,
    ),
    output: _DebugPrintOutput(_writeConsoleLine),
    filter: _AllowAllLogFilter(),
    level: logger.Level.trace,
  );

  /// 当前会话日志文件路径，便于后续直接定位并导出。
  String? get currentLogFilePath => _currentLogFile?.path;

  /// 初始化日志系统，并创建当前运行会话对应的日志文件。
  Future<void> init() {
    return _initTask ??= _initInternal();
  }

  /// 记录调试日志。
  void debug(String tag, String message, {Map<String, Object?>? context}) {
    _log(AppLogLevel.debug, tag, message, context: context);
  }

  /// 记录信息日志。
  void info(String tag, String message, {Map<String, Object?>? context}) {
    _log(AppLogLevel.info, tag, message, context: context);
  }

  /// 记录告警日志。
  void warn(String tag, String message, {Map<String, Object?>? context}) {
    _log(AppLogLevel.warn, tag, message, context: context);
  }

  /// 记录异常日志，并携带错误对象与堆栈。
  void error(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    _log(
      AppLogLevel.error,
      tag,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// 记录致命异常日志，通常用于应用未捕获异常。
  void fatal(
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    _log(
      AppLogLevel.fatal,
      tag,
      message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );
  }

  /// 记录结构化日志事件，供后续路由、HTTP 和业务日志统一接入。
  void logEvent(AppLogEvent event) {
    final Map<String, Object?> payload = event.toJson();
    final Map<String, Object?> consolePayload = <String, Object?>{
      'tag': payload['layer'] ?? 'APP',
      'event': payload['event'],
      'message': payload['message'],
      if (payload['result'] != null) 'result': payload['result'],
      if (payload['context'] != null) 'context': payload['context'],
    };

    _emitConsole(
      event.level,
      consolePayload,
      error: event.error,
      stackTrace: event.stackTrace,
    );
    _enqueueFilePayload(payload, immediate: _isCriticalLevel(event.level));
  }

  /// 读取当前运行会话的完整日志文本，便于后续复制粘贴问题现场。
  Future<String?> readCurrentLog() async {
    final file = _currentLogFile;
    if (file == null || !await file.exists()) {
      return null;
    }
    await _flushPendingFileLines();
    return file.readAsString();
  }

  /// 主动关闭日志输出流，避免进程退出前丢失缓冲区内容。
  Future<void> dispose() async {
    await _flushPendingFileLines();
    _flushTimer?.cancel();
    _flushTimer = null;
    final sink = _sink;
    _sink = null;
    if (sink == null) {
      return;
    }
    await sink.flush();
    await sink.close();
  }

  /// 初始化目录、清理历史日志，并落地当前会话文件。
  Future<void> _initInternal() async {
    final logDirectory = await _resolveLogDirectory();
    await logDirectory.create(recursive: true);
    await _cleanupExpiredLogs(logDirectory);

    final fileName = 'bluehub_${_compactDate(DateTime.now())}.log';
    final file = File('${logDirectory.path}/$fileName');
    _currentLogFile = file;
    _sink = file.openWrite(mode: FileMode.append);

    info(
      'LOGGER',
      '日志系统初始化完成',
      context: <String, Object?>{
        'path': file.path,
        'buildMode': kReleaseMode ? 'release' : 'debug',
      },
    );
  }

  /// 根据运行平台选择一个稳定可访问的日志目录。
  Future<Directory> _resolveLogDirectory() async {
    try {
      final supportDirectory = await getApplicationSupportDirectory();
      return Directory('${supportDirectory.path}/logs');
    } catch (_) {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      return Directory('${documentsDirectory.path}/logs');
    }
  }

  /// 仅保留最近几次运行产生的日志文件，避免目录无限增长。
  Future<void> _cleanupExpiredLogs(Directory directory) async {
    final entities = await directory.list().toList();
    final files = entities.whereType<File>().toList()
      ..sort(
        (File a, File b) =>
            b.path.toLowerCase().compareTo(a.path.toLowerCase()),
      );

    for (final file in files.skip(_maxLogFiles)) {
      try {
        await file.delete();
      } catch (_) {
        // 历史日志清理失败不影响当前流程。
      }
    }
  }

  /// 统一拼装单条日志，并串行写入文件，避免并发写乱序。
  void _log(
    AppLogLevel level,
    String tag,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? context,
  }) {
    final Map<String, Object?> payload = _buildConsolePayload(
      tag,
      message,
      context: context,
    );
    final Map<String, Object?> structuredPayload = _buildStructuredPayload(
      level: level,
      tag: tag,
      message: message,
      context: context,
      error: error,
      stackTrace: stackTrace,
    );

    _emitConsole(level, payload, error: error, stackTrace: stackTrace);
    _enqueueFilePayload(structuredPayload, immediate: _isCriticalLevel(level));
  }

  /// 构建控制台输出载荷，并统一复用上下文脱敏逻辑。
  Map<String, Object?> _buildConsolePayload(
    String tag,
    String message, {
    Map<String, Object?>? context,
  }) {
    return <String, Object?>{
      'tag': tag,
      'message': message,
      if (context != null && context.isNotEmpty)
        'context': sanitizeAppLogValue(context),
    };
  }

  /// 构建文件落盘使用的结构化载荷，保留详细字段便于本地排障。
  Map<String, Object?> _buildStructuredPayload({
    required AppLogLevel level,
    required String tag,
    required String message,
    Map<String, Object?>? context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    return <String, Object?>{
      'time': DateTime.now().toIso8601String(),
      'level': level.name.toUpperCase(),
      'tag': tag,
      'message': message,
      if (context != null && context.isNotEmpty)
        'context': sanitizeAppLogValue(context),
      if (error != null) 'error': truncateAppLogText(error.toString()),
      if (stackTrace != null)
        'stackTrace': truncateAppLogText(stackTrace.toString()),
    };
  }

  /// 按日志级别输出到控制台，保证结构化事件与传统日志共用同一通道。
  void _emitConsole(
    AppLogLevel level,
    Object payload, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    switch (level) {
      case AppLogLevel.debug:
        _logger.t(payload);
        break;
      case AppLogLevel.info:
        _logger.i(payload);
        break;
      case AppLogLevel.warn:
        _logger.w(payload);
        break;
      case AppLogLevel.error:
        _logger.e(payload, error: error, stackTrace: stackTrace);
        break;
      case AppLogLevel.fatal:
        _logger.f(payload, error: error, stackTrace: stackTrace);
        break;
    }
  }

  /// 控制台输出改用逐行 `debugPrint`，避免长行被截断。
  void _writeConsoleLine(String line) {
    debugPrint(line);
  }

  /// 将结构化载荷格式化成文本行并写入缓冲区，输出风格向 record4 项目靠齐。
  void _enqueueFilePayload(
    Map<String, Object?> payload, {
    required bool immediate,
  }) {
    _enqueueFileLine(_formatFileLine(payload), immediate: immediate);
  }

  /// 将日志文本追加到内存缓冲区，批量刷盘以降低频繁 I/O 抖动。
  void _enqueueFileLine(String line, {required bool immediate}) {
    final sink = _sink;
    if (sink == null) {
      return;
    }
    _pendingFileLines.add(line);
    if (immediate || _pendingFileLines.length >= _flushLineThreshold) {
      unawaited(_flushPendingFileLines());
      return;
    }
    _scheduleFlushTimer();
  }

  /// 串行冲刷当前缓冲区，保证文件落盘顺序稳定。
  Future<void> _flushPendingFileLines() async {
    final sink = _sink;
    if (sink == null || _isFlushing || _pendingFileLines.isEmpty) {
      return;
    }

    _isFlushing = true;
    _flushTimer?.cancel();
    _flushTimer = null;
    final List<String> batch = List<String>.from(_pendingFileLines);
    _pendingFileLines.clear();
    _writeQueue = _writeQueue
        .then((_) async {
          for (final line in batch) {
            sink.write(line);
          }
          await sink.flush();
        })
        .catchError((Object writeError, StackTrace writeStack) {
          debugPrint(
            '[LOGGER][ERROR] 日志写入失败 error=$writeError stack=$writeStack',
          );
        });
    try {
      await _writeQueue;
    } finally {
      _isFlushing = false;
      if (_pendingFileLines.isNotEmpty) {
        await _flushPendingFileLines();
      }
    }
  }

  /// 为缓冲写盘安排延迟任务，避免高频日志下频繁创建刷盘请求。
  void _scheduleFlushTimer() {
    if (_flushTimer != null && _flushTimer!.isActive) {
      return;
    }
    _flushTimer = Timer(_flushInterval, () {
      unawaited(_flushPendingFileLines());
    });
  }

  /// 将结构化载荷格式化成便于人工阅读的纯文本行日志。
  String _formatFileLine(Map<String, Object?> payload) {
    final String? httpBlock = _formatHttpBlock(payload);
    if (httpBlock != null) {
      return httpBlock;
    }

    final StringBuffer buffer = StringBuffer()
      ..write('[')
      ..write(_formatTime(payload['time']))
      ..write(']')
      ..write('[')
      ..write((payload['level']?.toString() ?? 'INFO').toLowerCase())
      ..write('] ');

    final String? primaryTag = _normalizePrimaryTag(payload);
    if (primaryTag != null) {
      buffer
        ..write('[')
        ..write(primaryTag)
        ..write(']');
    }

    final String? event = _normalizeText(payload['event']);
    if (event != null) {
      buffer
        ..write('[')
        ..write(event)
        ..write('] ');
    } else if (primaryTag != null) {
      buffer.write(' ');
    }

    final String message = _normalizeText(payload['message']) ?? '';
    buffer.write(message);

    final String suffix = _formatInlineFields(payload);
    if (suffix.isNotEmpty) {
      buffer
        ..write(' ')
        ..write(suffix);
    }

    final String? error = _normalizeText(payload['error']);
    if (error != null) {
      buffer
        ..write('\n')
        ..write('error: ')
        ..write(error);
    }

    final String? stackTrace = _normalizeText(payload['stackTrace']);
    if (stackTrace != null) {
      buffer
        ..write('\n')
        ..write('stack: ')
        ..write(stackTrace);
    }

    buffer.write('\n');
    return buffer.toString();
  }

  /// HTTP 请求/响应/失败日志改用多行块格式，提升长报文阅读体验。
  String? _formatHttpBlock(Map<String, Object?> payload) {
    final String? layer = _normalizeText(payload['layer']);
    final String? event = _normalizeText(payload['event']);
    if (layer != 'HTTP' || event == null) {
      return null;
    }

    final Object? rawContext = payload['context'];
    if (rawContext is! Map) {
      return null;
    }

    final Map<String, Object?> context = rawContext.map(
      (Object? key, Object? value) => MapEntry(key?.toString() ?? 'unknown', value),
    );
    final String method = _normalizeText(context['method']) ?? 'UNKNOWN';
    final String uri = _normalizeText(context['uri']) ?? '-';
    final String timestamp = _formatTime(payload['time']);
    final String level = (payload['level']?.toString() ?? 'INFO').toLowerCase();
    final StringBuffer buffer = StringBuffer();

    switch (event) {
      case 'HTTP_REQUEST_START':
        buffer.writeln('[$timestamp][$level] [http-request] [$method] $uri');
        _appendPrettySection(buffer, label: 'Headers', value: context['headers']);
        _appendPrettySection(buffer, label: 'Query', value: context['query']);
        _appendPrettySection(buffer, label: 'Body', value: context['body']);
        _appendInlineMeta(buffer, context, excludeKeys: <String>{
          'method',
          'uri',
          'headers',
          'query',
          'body',
        });
        return buffer.toString();
      case 'HTTP_REQUEST_SUCCESS':
        buffer.writeln('[$timestamp][$level] [http-response] [$method] $uri');
        _appendKeyValueLine(buffer, label: 'Status', value: context['statusCode']);
        _appendDurationLine(buffer, value: context['durationMs']);
        _appendResponseMessageLine(buffer, data: context['data']);
        _appendPrettySection(buffer, label: 'Data', value: context['data']);
        _appendInlineMeta(buffer, context, excludeKeys: <String>{
          'method',
          'uri',
          'statusCode',
          'durationMs',
          'data',
        });
        return buffer.toString();
      case 'HTTP_REQUEST_FAIL':
        buffer.writeln('[$timestamp][$level] [http-error] [$method] $uri');
        _appendKeyValueLine(buffer, label: 'Type', value: context['type']);
        _appendKeyValueLine(buffer, label: 'Status', value: context['statusCode']);
        _appendDurationLine(buffer, value: context['durationMs']);
        _appendKeyValueLine(buffer, label: 'Message', value: context['message']);
        _appendPrettySection(
          buffer,
          label: 'Response',
          value: context['response'],
        );
        _appendInlineMeta(buffer, context, excludeKeys: <String>{
          'method',
          'uri',
          'type',
          'statusCode',
          'durationMs',
          'message',
          'response',
        });
        final String? error = _normalizeText(payload['error']);
        if (error != null) {
          buffer.writeln('error: $error');
        }
        final String? stackTrace = _normalizeText(payload['stackTrace']);
        if (stackTrace != null) {
          buffer.writeln('stack: $stackTrace');
        }
        return buffer.toString();
    }

    return null;
  }

  /// 拼装内联字段文本，优先输出 result，再输出 context。
  String _formatInlineFields(Map<String, Object?> payload) {
    final List<String> fields = <String>[];
    final String? result = _normalizeText(payload['result']);
    if (result != null) {
      fields.add('result=$result');
    }

    final Object? context = payload['context'];
    if (context is Map) {
      context.forEach((Object? key, Object? value) {
        final String normalizedKey = key?.toString() ?? 'unknown';
        final String? normalizedValue = _formatContextValue(value);
        if (normalizedValue == null) {
          return;
        }
        fields.add('$normalizedKey=$normalizedValue');
      });
    }

    return fields.join(' ');
  }

  /// 为 HTTP 块追加多行 JSON 段。
  void _appendPrettySection(
    StringBuffer buffer, {
    required String label,
    Object? value,
  }) {
    if (value == null) {
      return;
    }
    final String pretty = _prettyFormat(value);
    if (pretty.isEmpty) {
      return;
    }
    buffer.writeln('$label: $pretty');
  }

  /// 为 HTTP 块追加单行键值。
  void _appendKeyValueLine(
    StringBuffer buffer, {
    required String label,
    Object? value,
  }) {
    final String? text = _normalizeText(value);
    if (text == null) {
      return;
    }
    buffer.writeln('$label: $text');
  }

  /// 为 HTTP 块追加耗时行。
  void _appendDurationLine(StringBuffer buffer, {Object? value}) {
    final String? text = _normalizeText(value);
    if (text == null) {
      return;
    }
    buffer.writeln('Time: $text ms');
  }

  /// 从响应数据中提取更接近接口语义的 message。
  void _appendResponseMessageLine(StringBuffer buffer, {Object? data}) {
    String? message;
    if (data is Map) {
      message =
          _normalizeText(data['message']) ??
          _normalizeText(data['msg']) ??
          _normalizeText(data['error']);
    }
    message ??= 'success';
    buffer.writeln('Message: $message');
  }

  /// 为 HTTP 块补充剩余元信息，避免关键链路字段完全丢失。
  void _appendInlineMeta(
    StringBuffer buffer,
    Map<String, Object?> context, {
    required Set<String> excludeKeys,
  }) {
    final List<String> fields = <String>[];
    context.forEach((String key, Object? value) {
      if (excludeKeys.contains(key)) {
        return;
      }
      final String? normalizedValue = _formatContextValue(value);
      if (normalizedValue == null) {
        return;
      }
      fields.add('$key=$normalizedValue');
    });
    if (fields.isEmpty) {
      return;
    }
    buffer.writeln('Meta: ${fields.join(' ')}');
  }

  /// 紧凑值走文本，复杂对象走缩进 JSON，便于多行日志阅读。
  String _prettyFormat(Object value) {
    if (value is Map || value is Iterable) {
      return const JsonEncoder.withIndent('  ').convert(value);
    }
    return value.toString();
  }

  /// 统一格式化上下文字段，复杂对象用紧凑 JSON 保留结构。
  String? _formatContextValue(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Map || value is Iterable) {
      return jsonEncode(value);
    }
    final text = value.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  /// 选择一条日志在文本风格中的主标签，普通日志走 tag，结构化日志走 layer。
  String? _normalizePrimaryTag(Map<String, Object?> payload) {
    return _normalizeText(payload['tag']) ?? _normalizeText(payload['layer']);
  }

  /// 统一格式化日志时间，输出 `yyyy-MM-dd HH:mm:ss.SSS`。
  String _formatTime(Object? rawTime) {
    final DateTime? time = rawTime == null
        ? null
        : DateTime.tryParse(rawTime.toString())?.toLocal();
    final DateTime resolved = time ?? DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    String threeDigits(int value) => value.toString().padLeft(3, '0');
    return '${resolved.year}-${twoDigits(resolved.month)}-${twoDigits(resolved.day)} '
        '${twoDigits(resolved.hour)}:${twoDigits(resolved.minute)}:${twoDigits(resolved.second)}.'
        '${threeDigits(resolved.millisecond)}';
  }

  /// 统一读取非空文本字段，避免日志中出现空白标签。
  String? _normalizeText(Object? value) {
    final String text = value?.toString().trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  /// 错误与致命日志触发即时刷盘，尽量减少异常现场丢失。
  bool _isCriticalLevel(AppLogLevel level) {
    return level == AppLogLevel.error || level == AppLogLevel.fatal;
  }

  /// 调试态更快刷盘，发布态提高阈值降低 I/O 干扰。
  Duration get _flushInterval =>
      kReleaseMode ? _releaseFlushInterval : _debugFlushInterval;

  /// 调试态使用更小缓冲条数，便于开发时更快看到落盘结果。
  int get _flushLineThreshold =>
      kReleaseMode ? _releaseFlushLineThreshold : _debugFlushLineThreshold;

  /// 生成按天归档的紧凑日期，确保同一天内的日志持续追加到同一文件。
  String _compactDate(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${time.year}'
        '${twoDigits(time.month)}'
        '${twoDigits(time.day)}';
  }
}

/// 控制台输出器：逐行交给 `debugPrint`，保留 PrettyPrinter 的多行格式。
class _DebugPrintOutput extends logger.LogOutput {
  _DebugPrintOutput(this._writer);

  final void Function(String line) _writer;

  @override
  void output(logger.OutputEvent event) {
    for (final line in event.lines) {
      _writer(line);
    }
  }
}

/// 自定义过滤器：无论调试版还是发布版，都保留完整日志级别。
class _AllowAllLogFilter extends logger.LogFilter {
  @override
  bool shouldLog(logger.LogEvent event) => true;
}
