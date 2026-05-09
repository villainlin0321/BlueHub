import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart' as logger;
import 'package:path_provider/path_provider.dart';

/// 日志级别：用于区分常规信息、告警和异常。
enum AppLogLevel { debug, info, warn, error, fatal }

/// 全局日志类：统一负责控制台输出、本地文件落盘和日志文件读取。
class AppLogger {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const int _maxLogFiles = 7;
  static const int _maxFieldLength = 1500;

  IOSink? _sink;
  File? _currentLogFile;
  Future<void>? _initTask;
  Future<void> _writeQueue = Future<void>.value();
  late final logger.Logger _logger = logger.Logger(
    printer: _AppLogPrinter(_sanitizeValue, _truncate),
    output: _AppLogOutput(_writeLine),
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

  /// 读取当前运行会话的完整日志文本，便于后续复制粘贴问题现场。
  Future<String?> readCurrentLog() async {
    final file = _currentLogFile;
    if (file == null || !await file.exists()) {
      return null;
    }
    return file.readAsString();
  }

  /// 主动关闭日志输出流，避免进程退出前丢失缓冲区内容。
  Future<void> dispose() async {
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

    final fileName = 'bluehub_${_compactTimestamp(DateTime.now())}.log';
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
    final payload = <String, Object?>{
      'tag': tag,
      'message': message,
      if (context != null && context.isNotEmpty) 'context': context,
    };

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

  /// 串行写入日志行，避免并发场景下输出顺序错乱。
  void _writeLine(String line) {
    debugPrint(line);

    final sink = _sink;
    if (sink == null) {
      return;
    }

    _writeQueue = _writeQueue
        .then((_) async {
          sink.writeln(line);
          await sink.flush();
        })
        .catchError((Object writeError, StackTrace writeStack) {
          debugPrint(
            '[LOGGER][ERROR] 日志写入失败 error=$writeError stack=$writeStack',
          );
        });
  }

  /// 对上下文字段做脱敏和长度裁剪，避免 token、密码等敏感信息泄露。
  Object? _sanitizeValue(Object? value, {String? key}) {
    if (value == null) {
      return null;
    }

    if (value is Map) {
      return value.map((Object? currentKey, Object? currentValue) {
        final normalizedKey = currentKey?.toString() ?? 'unknown';
        return MapEntry<String, Object?>(
          normalizedKey,
          _sanitizeValue(currentValue, key: normalizedKey),
        );
      });
    }

    if (value is Iterable) {
      return value.map((Object? item) => _sanitizeValue(item)).toList();
    }

    final text = _truncate(value.toString());
    if (_isSensitiveKey(key)) {
      return '***';
    }
    return text;
  }

  /// 判断字段名是否包含敏感信息关键字。
  bool _isSensitiveKey(String? key) {
    if (key == null) {
      return false;
    }
    final normalized = key.toLowerCase();
    return normalized.contains('token') ||
        normalized.contains('authorization') ||
        normalized.contains('password') ||
        normalized.contains('secret');
  }

  /// 防止超长文本撑爆日志文件，保留前缀便于快速定位问题。
  String _truncate(String text) {
    if (text.length <= _maxFieldLength) {
      return text;
    }
    return '${text.substring(0, _maxFieldLength)}...(truncated)';
  }

  /// 生成紧凑时间戳，便于用文件名区分不同启动会话。
  String _compactTimestamp(DateTime time) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${time.year}'
        '${twoDigits(time.month)}'
        '${twoDigits(time.day)}_'
        '${twoDigits(time.hour)}'
        '${twoDigits(time.minute)}'
        '${twoDigits(time.second)}';
  }
}

/// 自定义日志打印器：统一把第三方日志事件转换为单行 JSON 文本。
class _AppLogPrinter extends logger.LogPrinter {
  _AppLogPrinter(this._sanitizeValue, this._truncate);

  final Object? Function(Object? value, {String? key}) _sanitizeValue;
  final String Function(String text) _truncate;

  @override
  List<String> log(logger.LogEvent event) {
    final payload = event.message is Map<String, Object?>
        ? Map<String, Object?>.from(event.message as Map<String, Object?>)
        : <String, Object?>{'message': event.message.toString()};

    final tag = payload.remove('tag')?.toString() ?? 'APP';
    final message = payload.remove('message')?.toString() ?? '';
    final context = payload.remove('context');

    final line = jsonEncode(<String, Object?>{
      'time': DateTime.now().toIso8601String(),
      'level': event.level.name.toUpperCase(),
      'tag': tag,
      'message': message,
      if (context != null) 'context': _sanitizeValue(context),
      if (event.error != null) 'error': _truncate(event.error.toString()),
      if (event.stackTrace != null)
        'stackTrace': _truncate(event.stackTrace.toString()),
    });

    return <String>[line];
  }
}

/// 自定义输出器：把格式化后的日志同时交给控制台和文件落盘链路。
class _AppLogOutput extends logger.LogOutput {
  _AppLogOutput(this._writer);

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
