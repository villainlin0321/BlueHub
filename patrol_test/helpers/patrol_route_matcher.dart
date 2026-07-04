import 'package:flutter/material.dart';

/// 描述一个路由在 Patrol 场景下如何判断“页面已就绪”。
class PatrolRouteMatcher {
  /// 创建路由匹配描述，支持优先使用稳定 Key，再退回文本锚点。
  const PatrolRouteMatcher({
    required this.routePath,
    this.readyKey,
    this.fallbackText,
  });

  final String routePath;
  final Key? readyKey;
  final String? fallbackText;
}
