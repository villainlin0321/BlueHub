import 'dart:convert';

import 'package:europepass/shared/logging/app_log_facade.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod 观察器：只记录高价值 Provider 的创建、变化和失败事件。
final class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  static const List<String> _highValueProviderKeywords = <String>[
    'auth',
    'session',
    'controller',
    'role',
    'router',
    'shell',
  ];

  @override
  /// 记录高价值 Provider 的首次创建结果，帮助确认关键状态链路已挂载。
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (!_shouldObserve(context)) {
      return;
    }

    StateLog.log(
      event: 'PROVIDER_ADDED',
      message: 'Provider 已创建',
      context: <String, Object?>{
        'provider': _describeProvider(context),
        if (value != null) 'value': value.toString(),
      },
    );
  }

  @override
  /// 记录高价值 Provider 的状态变化，但会跳过前后文本快照一致的噪音更新。
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (!_shouldObserve(context)) {
      return;
    }

    final previousSnapshot = _stringifyValue(previousValue);
    final nextSnapshot = _stringifyValue(newValue);
    if (_shouldSkipUpdate(previousValue, newValue)) {
      return;
    }

    StateLog.providerChanged(
      provider: _describeProvider(context),
      previousValue: previousSnapshot,
      newValue: nextSnapshot,
      context: <String, Object?>{
        if (context.mutation != null) 'mutation': context.mutation.toString(),
      },
    );
  }

  @override
  /// 记录高价值 Provider 的执行失败，便于串联状态层异常现场。
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!_shouldObserve(context)) {
      return;
    }

    StateLog.providerFailed(
      provider: _describeProvider(context),
      error: error,
      stackTrace: stackTrace,
      context: <String, Object?>{
        if (context.mutation != null) 'mutation': context.mutation.toString(),
      },
    );
  }

  /// 判断当前 Provider 是否属于值得记录的高价值状态链路。
  bool _shouldObserve(ProviderObserverContext context) {
    final providerDescription = _describeProvider(context).toLowerCase();
    for (final keyword in _highValueProviderKeywords) {
      if (providerDescription.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  /// 生成稳定的 Provider 描述文本，便于日志搜索与统计。
  String _describeProvider(ProviderObserverContext context) {
    return context.provider.toString();
  }

  /// 判断一次更新是否只是基础类型或集合层面的重复写入，避免简单场景日志过噪。
  bool _shouldSkipUpdate(Object? previousValue, Object? newValue) {
    if (identical(previousValue, newValue)) {
      return true;
    }

    final previousComparableSnapshot = _buildComparableSnapshot(previousValue);
    final nextComparableSnapshot = _buildComparableSnapshot(newValue);
    if (previousComparableSnapshot == null || nextComparableSnapshot == null) {
      // 关键保护：复杂对象缺少稳定快照时宁可保留日志，也不能误吞关键状态更新。
      return false;
    }
    return jsonEncode(previousComparableSnapshot) ==
        jsonEncode(nextComparableSnapshot);
  }

  /// 将 Provider 值压成文本快照，避免复杂对象直接写日志时再次抛错。
  String? _stringifyValue(Object? value) {
    if (value == null) {
      return null;
    }

    final comparableSnapshot = _buildComparableSnapshot(value);
    if (comparableSnapshot != null) {
      if (comparableSnapshot is String) {
        return comparableSnapshot;
      }
      return jsonEncode(comparableSnapshot);
    }

    final valueText = value.toString();
    if (_looksLikeOpaqueObjectDescription(value, valueText)) {
      return '${value.runtimeType}#${identityHashCode(value)}';
    }
    return valueText;
  }

  /// 为基础类型和集合生成稳定快照，只在这些可判等对象上做去噪。
  Object? _buildComparableSnapshot(Object? value) {
    if (value == null ||
        value is num ||
        value is bool ||
        value is String ||
        value is Enum) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Uri) {
      return value.toString();
    }
    if (value is Iterable<Object?>) {
      return value.map<Object?>((Object? item) => _buildComparableSnapshot(item)).toList();
    }
    if (value is Map<Object?, Object?>) {
      final List<MapEntry<String, Object?>> entries = value.entries
          .map(
            (MapEntry<Object?, Object?> entry) => MapEntry<String, Object?>(
              entry.key?.toString() ?? 'null',
              _buildComparableSnapshot(entry.value),
            ),
          )
          .toList()
        ..sort(
          (
            MapEntry<String, Object?> left,
            MapEntry<String, Object?> right,
          ) => left.key.compareTo(right.key),
        );
      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value,
      };
    }
    return null;
  }

  /// 识别默认 `Object.toString()` 这类无信息量文本，避免日志里前后值看起来完全相同。
  bool _looksLikeOpaqueObjectDescription(Object value, String valueText) {
    return valueText == "Instance of '${value.runtimeType}'";
  }
}
