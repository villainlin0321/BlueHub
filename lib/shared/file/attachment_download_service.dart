import 'dart:io';

import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

enum AttachmentDownloadErrorType {
  fileNotFound,
  noWritableDirectory,
  galleryAccessDenied,
  gallerySaveFailed,
}

class AttachmentDownloadException implements Exception {
  const AttachmentDownloadException(this.type);

  final AttachmentDownloadErrorType type;
}

class AttachmentDownloadResult {
  const AttachmentDownloadResult._({
    required this.savedToGallery,
    this.localPath,
  });

  const AttachmentDownloadResult.savedToGallery()
    : this._(savedToGallery: true);

  const AttachmentDownloadResult.savedToFile(String path)
    : this._(savedToGallery: false, localPath: path);

  final bool savedToGallery;
  final String? localPath;
}

/// 统一处理附件下载与图片落图库。
class AttachmentDownloadService {
  AttachmentDownloadService._();

  static const String _downloadFolderName = 'BlueHub';
  static const String _stagingFolderName = 'attachment_download_staging';

  /// 图片统一保存到系统相册；非图片保存到可写下载目录。
  static Future<AttachmentDownloadResult> save({
    required String sourcePath,
    required String fileName,
    required bool isImage,
    Dio? dio,
  }) async {
    if (_isRemoteFilePath(sourcePath)) {
      return isImage
          ? _saveRemoteImage(
              sourcePath: sourcePath,
              fileName: fileName,
              dio: dio,
            )
          : _saveRemoteFileToDirectory(
              sourcePath: sourcePath,
              fileName: fileName,
              dio: dio,
            );
    }

    return isImage
        ? _saveLocalImage(sourcePath: sourcePath, fileName: fileName)
        : _copyLocalFileToDirectory(sourcePath: sourcePath, fileName: fileName);
  }

  static bool _isRemoteFilePath(String path) {
    final Uri? uri = Uri.tryParse(path);
    return uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https');
  }

  static Future<AttachmentDownloadResult> _saveRemoteImage({
    required String sourcePath,
    required String fileName,
    Dio? dio,
  }) async {
    final File stagedFile = await _createStagingFile(fileName);
    final Dio downloadClient = dio ?? Dio();
    final bool shouldCloseDio = dio == null;
    try {
      await downloadClient.download(
        sourcePath,
        stagedFile.path,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
        deleteOnError: true,
      );
      return await _saveLocalImage(sourcePath: stagedFile.path, fileName: fileName);
    } finally {
      if (shouldCloseDio) {
        downloadClient.close(force: true);
      }
      if (await stagedFile.exists()) {
        await stagedFile.delete();
      }
    }
  }

  static Future<AttachmentDownloadResult> _saveLocalImage({
    required String sourcePath,
    required String fileName,
  }) async {
    final File imageFile = File(sourcePath);
    if (!await imageFile.exists()) {
      throw const AttachmentDownloadException(
        AttachmentDownloadErrorType.fileNotFound,
      );
    }
    try {
      return await _saveLocalImageToGallery(imageFile.path);
    } on AttachmentDownloadException {
      return _copyLocalFileToDirectory(
        sourcePath: imageFile.path,
        fileName: fileName,
      );
    }
  }

  static Future<AttachmentDownloadResult> _saveLocalImageToGallery(
    String sourcePath,
  ) async {
    try {
      if (!await Gal.hasAccess()) {
        final bool granted = await Gal.requestAccess();
        if (!granted) {
          throw const AttachmentDownloadException(
            AttachmentDownloadErrorType.galleryAccessDenied,
          );
        }
      }
      await Gal.putImage(sourcePath);
      return const AttachmentDownloadResult.savedToGallery();
    } on AttachmentDownloadException {
      rethrow;
    } on GalException catch (error) {
      if (error.type == GalExceptionType.accessDenied) {
        throw const AttachmentDownloadException(
          AttachmentDownloadErrorType.galleryAccessDenied,
        );
      }
      throw const AttachmentDownloadException(
        AttachmentDownloadErrorType.gallerySaveFailed,
      );
    } catch (_) {
      throw const AttachmentDownloadException(
        AttachmentDownloadErrorType.gallerySaveFailed,
      );
    }
  }

  static Future<AttachmentDownloadResult> _saveRemoteFileToDirectory({
    required String sourcePath,
    required String fileName,
    Dio? dio,
  }) async {
    final Directory directory = await _resolveDownloadDirectory();
    final String savePath = await _buildUniqueSavePath(directory, fileName);
    final Dio downloadClient = dio ?? Dio();
    final bool shouldCloseDio = dio == null;
    try {
      await downloadClient.download(
        sourcePath,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
        deleteOnError: true,
      );
      return AttachmentDownloadResult.savedToFile(savePath);
    } finally {
      if (shouldCloseDio) {
        downloadClient.close(force: true);
      }
    }
  }

  static Future<AttachmentDownloadResult> _copyLocalFileToDirectory({
    required String sourcePath,
    required String fileName,
  }) async {
    final File localFile = File(sourcePath);
    if (!await localFile.exists()) {
      throw const AttachmentDownloadException(
        AttachmentDownloadErrorType.fileNotFound,
      );
    }
    final Directory directory = await _resolveDownloadDirectory();
    final String savePath = await _buildUniqueSavePath(directory, fileName);
    await localFile.copy(savePath);
    return AttachmentDownloadResult.savedToFile(savePath);
  }

  static Future<File> _createStagingFile(String fileName) async {
    final Directory temporaryDirectory = await getTemporaryDirectory();
    final Directory stagingDirectory = Directory(
      '${temporaryDirectory.path}/$_stagingFolderName',
    );
    if (!await stagingDirectory.exists()) {
      await stagingDirectory.create(recursive: true);
    }
    final String savePath = await _buildUniqueSavePath(stagingDirectory, fileName);
    return File(savePath);
  }

  static Future<Directory> _resolveDownloadDirectory() async {
    final List<Directory> candidates = <Directory>[];
    if (Platform.isAndroid) {
      try {
        final Directory? downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory != null) {
          candidates.add(Directory('${downloadsDirectory.path}/$_downloadFolderName'));
        }
      } catch (_) {}
      try {
        final Directory documentsDirectory =
            await getApplicationDocumentsDirectory();
        candidates.add(Directory('${documentsDirectory.path}/downloads'));
      } catch (_) {}
    } else if (Platform.isIOS) {
      try {
        final Directory temporaryDirectory = await getTemporaryDirectory();
        candidates.add(Directory('${temporaryDirectory.path}/downloads'));
      } catch (_) {}
    } else {
      try {
        final Directory? downloadsDirectory = await getDownloadsDirectory();
        if (downloadsDirectory != null) {
          candidates.add(Directory('${downloadsDirectory.path}/$_downloadFolderName'));
        }
      } catch (_) {}
      try {
        final Directory documentsDirectory =
            await getApplicationDocumentsDirectory();
        candidates.add(Directory('${documentsDirectory.path}/downloads'));
      } catch (_) {}
    }

    final Directory temporaryDirectory = await getTemporaryDirectory();
    candidates.add(Directory('${temporaryDirectory.path}/downloads'));

    for (final Directory candidate in candidates) {
      if (await _canWriteToDirectory(candidate)) {
        return candidate;
      }
    }
    throw const AttachmentDownloadException(
      AttachmentDownloadErrorType.noWritableDirectory,
    );
  }

  static Future<bool> _canWriteToDirectory(Directory directory) async {
    try {
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final File probeFile = File(
        '${directory.path}/.bluehub_write_test_${DateTime.now().microsecondsSinceEpoch}',
      );
      await probeFile.writeAsString('ok', flush: true);
      if (await probeFile.exists()) {
        await probeFile.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> _buildUniqueSavePath(
    Directory directory,
    String fileName,
  ) async {
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    final String sanitizedName = _sanitizeFileName(fileName);
    String savePath = '${directory.path}/$sanitizedName';
    if (!await File(savePath).exists()) {
      return savePath;
    }
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final int dotIndex = sanitizedName.lastIndexOf('.');
    final String uniqueName = dotIndex > 0
        ? '${sanitizedName.substring(0, dotIndex)}_$timestamp${sanitizedName.substring(dotIndex)}'
        : '${sanitizedName}_$timestamp';
    savePath = '${directory.path}/$uniqueName';
    return savePath;
  }

  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
