import 'dart:io';

import 'package:flutter/widgets.dart';

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

  /// 根据路径构造图片提供者，支持本地文件与网络图片两种来源。
  static ImageProvider<Object>? resolveImageProvider(String? path) {
    final String? normalizedPath = path?.trim();
    if (normalizedPath == null || normalizedPath.isEmpty) {
      return null;
    }
    if (_isNetworkPath(normalizedPath)) {
      return NetworkImage(normalizedPath);
    }
    return FileImage(File(normalizedPath));
  }

  /// 判断当前路径是否为可直接展示的网络图片地址。
  static bool _isNetworkPath(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }
}
