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
    if (previousSnapshot == nextSnapshot) {
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

  /// 将 Provider 值压成文本快照，避免复杂对象直接写日志时再次抛错。
  String? _stringifyValue(Object? value) {
    return value?.toString();
  }
}
