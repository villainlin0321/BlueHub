import 'qualification_certification_flow.dart';

/// 统一解析资质认证页面的预览图片来源，兼容本地临时文件与后端图片地址。
class QualificationPreviewResolver {
  const QualificationPreviewResolver._();

  /// 优先返回本地预览路径；本地路径缺失时退回后端返回的 `fileUrl`。
  static String? resolvePreviewPath(UploadedQualificationDoc? document) {
    if (document == null) {
      return null;
    }
    final String localPath = document.localPath.trim();
    if (localPath.isNotEmpty) {
      return localPath;
    }
    final String fileUrl = document.fileUrl.trim();
    return fileUrl.isEmpty ? null : fileUrl;
  }

  /// 判断当前路径是否为可直接展示的网络图片地址。
  static bool isNetworkPath(String? path) {
    final String normalizedPath = path?.trim() ?? '';
    return normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://');
  }
}
