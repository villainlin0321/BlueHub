/// 生成 Patrol 失败或阻塞截图的文件名。
String buildPatrolScreenshotFileName({
  required String page,
  required String feature,
  required DateTime now,
}) {
  // 仅保留稳定字符，避免跨平台文件名兼容性问题。
  final sanitizedName = '${page}_$feature'.replaceAll(
    RegExp(r'[^a-zA-Z0-9_]+'),
    '_',
  );
  final timestamp = now.toIso8601String().replaceAll(':', '-');
  return '${timestamp}_$sanitizedName.png';
}
