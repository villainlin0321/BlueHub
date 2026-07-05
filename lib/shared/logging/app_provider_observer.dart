import 'dart:convert';

import 'package:europepass/features/auth/application/auth_session_state.dart';
import 'package:europepass/features/auth/application/auth_user.dart';
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
        if (value != null) 'value': _buildLogValue(value),
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

    final previousSnapshot = _buildLogValue(previousValue);
    final nextSnapshot = _buildLogValue(newValue);
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
    final String? previousEncodedSnapshot = _tryEncodeComparableSnapshot(
      previousComparableSnapshot,
    );
    final String? nextEncodedSnapshot = _tryEncodeComparableSnapshot(
      nextComparableSnapshot,
    );
    if (previousEncodedSnapshot == null || nextEncodedSnapshot == null) {
      // 关键保护：即便快照编码失败，也只能退化为“保留日志”，不能让观察器抛异常。
      return false;
    }
    return previousEncodedSnapshot == nextEncodedSnapshot;
  }

  /// 为日志输出构建受控快照，让高价值复杂对象也能保留关键字段变化。
  Object? _buildLogValue(Object? value) {
    if (value == null) {
      return null;
    }

    final structuredSnapshot = _buildComparableSnapshot(value);
    if (structuredSnapshot != null) {
      return structuredSnapshot;
    }

    final valueText = value.toString();
    if (_looksLikeOpaqueObjectDescription(value, valueText)) {
      return '${value.runtimeType}#${identityHashCode(value)}';
    }
    return valueText;
  }

  /// 为可判等的 Provider 值生成稳定快照，既用于去噪，也复用于结构化日志输出。
  Object? _buildComparableSnapshot(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is Enum) {
      // 关键保护：Enum 直接 `jsonEncode` 会抛异常，这里统一转成稳定字符串快照。
      return '${value.runtimeType}.${value.name}';
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Uri) {
      return value.toString();
    }
    final domainSnapshot = _buildDomainSnapshot(value);
    if (domainSnapshot != null) {
      return domainSnapshot;
    }
    if (value is Iterable) {
      return value
          .map<Object?>((Object? item) => _buildComparableSnapshot(item))
          .toList();
    }
    if (value is Map) {
      final List<MapEntry<String, Object?>> entries =
          value.entries
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

  /// 安全编码可比较快照；若编码失败则返回 `null`，由调用方退化为“保留日志”。
  String? _tryEncodeComparableSnapshot(Object snapshot) {
    try {
      return jsonEncode(snapshot);
    } on JsonUnsupportedObjectError {
      return null;
    }
  }

  /// 针对无稳定 `toString()` 的关键业务对象做显式字段提取，避免日志退化成对象地址。
  Map<String, Object?>? _buildDomainSnapshot(Object value) {
    if (value is AuthSessionState) {
      return _buildAuthSessionStateSnapshot(value);
    }
    if (value is AuthUser) {
      return _buildAuthUserSnapshot(value);
    }
    return null;
  }

  /// 提取鉴权会话的核心字段，确保登录态变化可以直接从日志中回放。
  Map<String, Object?> _buildAuthSessionStateSnapshot(AuthSessionState value) {
    return <String, Object?>{
      '_type': 'AuthSessionState',
      'isAuthenticated': value.isAuthenticated,
      'isHydrating': value.isHydrating,
      'needSelectRole': value.needSelectRole,
      'user': _buildComparableSnapshot(value.user),
    };
  }

  /// 提取当前登录用户的关键字段，便于排查角色切换与会话恢复问题。
  Map<String, Object?> _buildAuthUserSnapshot(AuthUser value) {
    return <String, Object?>{
      '_type': 'AuthUser',
      'userId': value.userId,
      'phone': value.phone,
      'countryCode': value.countryCode,
      'email': value.email,
      'nickname': value.nickname,
      'avatarUrl': value.avatarUrl,
      'role': value.role,
      'gender': value.gender,
      'birthday': value.birthday,
      'currentLocation': value.currentLocation,
      'isVerified': value.isVerified,
    };
  }

  /// 识别默认 `Object.toString()` 这类无信息量文本，避免日志里前后值看起来完全相同。
  bool _looksLikeOpaqueObjectDescription(Object value, String valueText) {
    return valueText == "Instance of '${value.runtimeType}'";
  }
}
