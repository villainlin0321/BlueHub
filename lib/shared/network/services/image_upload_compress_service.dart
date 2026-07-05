import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';

class PreparedUploadPayload {
  const PreparedUploadPayload({
    required this.bytes,
    required this.mimeType,
    required this.fileSize,
    required this.isImage,
    required this.isCompressed,
    required this.exceedsMaxSizeLimit,
  });

  final List<int> bytes;
  final String mimeType;
  final int fileSize;
  final bool isImage;
  final bool isCompressed;
  final bool exceedsMaxSizeLimit;
}

class ImageInfoForCompress {
  const ImageInfoForCompress({required this.width, required this.height});

  final int width;
  final int height;
}

abstract class ImageCompressionEngine {
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  });
}

class FlutterImageCompressionEngine implements ImageCompressionEngine {
  @override
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) {
    return FlutterImageCompress.compressWithFile(
      path,
      format: format,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      keepExif: format == CompressFormat.jpeg,
    );
  }
}

class ImageUploadCompressService {
  ImageUploadCompressService({
    ImageCompressionEngine? engine,
    Future<Uint8List> Function(String path)? readFileBytes,
    Future<ImageInfoForCompress?> Function(String path)? readImageInfo,
  }) : _engine = engine ?? FlutterImageCompressionEngine(),
       _readFileBytes = readFileBytes ?? _defaultReadFileBytes,
       _readImageInfo = readImageInfo ?? _defaultReadImageInfo;

  static const int maxLongSide = 1920;
  static const int maxShortSide = 1080;
  static const int maxUploadImageSize = 10 * 1024 * 1024;
  static const List<int> qualitySteps = <int>[80, 70, 60, 50, 40];
  static const Map<String, _SafeCompressionTarget> _safeCompressionTargets =
      <String, _SafeCompressionTarget>{
        'jpg': _SafeCompressionTarget(
          format: CompressFormat.jpeg,
          mimeType: 'image/jpeg',
        ),
        'jpeg': _SafeCompressionTarget(
          format: CompressFormat.jpeg,
          mimeType: 'image/jpeg',
        ),
        'png': _SafeCompressionTarget(
          format: CompressFormat.png,
          mimeType: 'image/png',
        ),
      };
  static const Set<String> _skippedImageMimeSubtypes = <String>{
    'gif',
    'svg+xml',
    'webp',
    'bmp',
    'heic',
    'heif',
  };

  final ImageCompressionEngine _engine;
  final Future<Uint8List> Function(String path) _readFileBytes;
  final Future<ImageInfoForCompress?> Function(String path) _readImageInfo;

  static ({int width, int height}) resolveTargetDimensions({
    required int width,
    required int height,
    required int maxLongSide,
    required int maxShortSide,
  }) {
    if (width <= 0 || height <= 0) {
      return (width: maxLongSide, height: maxLongSide);
    }

    final int longSide = width > height ? width : height;
    final int shortSide = width > height ? height : width;
    if (longSide <= maxLongSide) {
      return (width: width, height: height);
    }
    if (shortSide <= maxShortSide) {
      return (width: width, height: height);
    }

    final double longSideScale = longSide / maxLongSide;
    final double shortSideScale = shortSide / maxShortSide;
    final double limitScale = longSideScale < shortSideScale
        ? longSideScale
        : shortSideScale;
    final double scale = 1 / limitScale;
    return (
      width: (width * scale).round().clamp(1, width),
      height: (height * scale).round().clamp(1, height),
    );
  }

  Future<PreparedUploadPayload> prepareForUpload({
    required String filePath,
    required String mimeType,
  }) async {
    final Uint8List originalBytes = await _readFileBytes(filePath);
    final _SafeCompressionTarget? compressionTarget = _resolveCompressionTarget(
      mimeType: mimeType,
    );
    final bool isImage = _isImageMimeType(mimeType);
    if (compressionTarget == null) {
      return _buildOriginalPayload(
        mimeType: mimeType,
        originalBytes: originalBytes,
        isImage: isImage,
      );
    }

    final ImageInfoForCompress? imageInfo = await _readImageInfo(filePath);
    if (imageInfo == null) {
      return _buildOriginalPayload(
        mimeType: mimeType,
        originalBytes: originalBytes,
        isImage: true,
      );
    }

    final ({int width, int height}) target = resolveTargetDimensions(
      width: imageInfo.width,
      height: imageInfo.height,
      maxLongSide: maxLongSide,
      maxShortSide: maxShortSide,
    );

    Uint8List? lastBytes;
    for (final int quality in qualitySteps) {
      final Uint8List? compressed;
      try {
        compressed = await _engine.compress(
          path: filePath,
          format: compressionTarget.format,
          quality: quality,
          minWidth: target.width,
          minHeight: target.height,
        );
      } catch (_) {
        return _buildOriginalPayload(
          mimeType: mimeType,
          originalBytes: originalBytes,
          isImage: true,
        );
      }
      if (compressed == null || compressed.isEmpty) {
        continue;
      }
      lastBytes = compressed;
      if (compressed.length <= maxUploadImageSize) {
        return PreparedUploadPayload(
          bytes: compressed,
          mimeType: compressionTarget.mimeType,
          fileSize: compressed.length,
          isImage: true,
          isCompressed: true,
          exceedsMaxSizeLimit: false,
        );
      }
    }

    final List<int> finalBytes = lastBytes ?? originalBytes;
    return PreparedUploadPayload(
      bytes: finalBytes,
      mimeType: lastBytes == null ? mimeType : compressionTarget.mimeType,
      fileSize: finalBytes.length,
      isImage: true,
      isCompressed: lastBytes != null,
      exceedsMaxSizeLimit: finalBytes.length > maxUploadImageSize,
    );
  }

  _SafeCompressionTarget? _resolveCompressionTarget({
    required String mimeType,
  }) {
    final String normalizedMimeType = _normalizeMimeType(mimeType);
    if (!_isImageMimeType(normalizedMimeType)) {
      return null;
    }

    final int slashIndex = normalizedMimeType.indexOf('/');
    if (slashIndex < 0 || slashIndex == normalizedMimeType.length - 1) {
      return null;
    }

    final String subtype = normalizedMimeType.substring(slashIndex + 1);
    if (_skippedImageMimeSubtypes.contains(subtype)) {
      return null;
    }
    return _safeCompressionTargets[subtype];
  }

  bool _isImageMimeType(String mimeType) {
    return _normalizeMimeType(mimeType).startsWith('image/');
  }

  String _normalizeMimeType(String mimeType) {
    return mimeType.toLowerCase().split(';').first.trim();
  }

  PreparedUploadPayload _buildOriginalPayload({
    required String mimeType,
    required Uint8List originalBytes,
    required bool isImage,
  }) {
    return PreparedUploadPayload(
      bytes: originalBytes,
      mimeType: mimeType,
      fileSize: originalBytes.length,
      isImage: isImage,
      isCompressed: false,
      exceedsMaxSizeLimit: isImage && originalBytes.length > maxUploadImageSize,
    );
  }

  static Future<Uint8List> _defaultReadFileBytes(String path) async {
    return File(path).readAsBytes();
  }

  static Future<ImageInfoForCompress?> _defaultReadImageInfo(
    String path,
  ) async {
    try {
      final Uint8List bytes = await _defaultReadFileBytes(path);
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final ImageInfoForCompress info = ImageInfoForCompress(
        width: frame.image.width,
        height: frame.image.height,
      );
      frame.image.dispose();
      codec.dispose();
      return info;
    } catch (_) {
      return null;
    }
  }
}

class _SafeCompressionTarget {
  const _SafeCompressionTarget({required this.format, required this.mimeType});

  final CompressFormat format;
  final String mimeType;
}
