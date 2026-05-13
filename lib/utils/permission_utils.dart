import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  PermissionUtils._();

  static Future<bool> requestCameraPermission() async {
    return _requestPermission(Permission.camera);
  }

  static Future<bool> requestGalleryPermission() async {
    if (Platform.isIOS) {
      return _requestPermission(Permission.photos);
    }
    if (Platform.isAndroid) {
      final PermissionStatus photosStatus = await Permission.photos.request();
      if (_isGranted(photosStatus)) {
        return true;
      }
      return _requestPermission(Permission.storage);
    }
    return true;
  }

  static Future<bool> _requestPermission(Permission permission) async {
    final PermissionStatus status = await permission.request();
    return _isGranted(status);
  }

  static bool _isGranted(PermissionStatus status) {
    return status.isGranted || status.isLimited;
  }
}
