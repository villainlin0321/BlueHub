import 'dart:typed_data';

import 'package:europepass/shared/network/services/image_upload_compress_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('宽高异常时回退到 1920x1920', () {
    final result = ImageUploadCompressService.resolveTargetDimensions(
      width: 0,
      height: 100,
      maxLongSide: 1920,
      maxShortSide: 1080,
    );

    expect(result.width, 1920);
    expect(result.height, 1920);
  });

  test('长边未超过 1920 时保留原尺寸', () {
    final result = ImageUploadCompressService.resolveTargetDimensions(
      width: 1600,
      height: 900,
      maxLongSide: 1920,
      maxShortSide: 1080,
    );

    expect(result.width, 1600);
    expect(result.height, 900);
  });

  test('短边未超过 1080 时保留原尺寸', () {
    final result = ImageUploadCompressService.resolveTargetDimensions(
      width: 4000,
      height: 900,
      maxLongSide: 1920,
      maxShortSide: 1080,
    );

    expect(result.width, 4000);
    expect(result.height, 900);
  });

  test('同时超过长短边限制时按参考公式等比缩放', () {
    final result = ImageUploadCompressService.resolveTargetDimensions(
      width: 4000,
      height: 3000,
      maxLongSide: 1920,
      maxShortSide: 1080,
    );

    expect(result.width, 1440);
    expect(result.height, 1080);
  });

  test('非图片文件直接跳过压缩并保留原始内容', () async {
    final service = ImageUploadCompressService(
      engine: _FakeCompressionEngine(),
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 100, height: 100),
      readFileBytes: (_) async => Uint8List.fromList(<int>[1, 2, 3]),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/demo.pdf',
      mimeType: 'application/pdf',
    );

    expect(payload.isImage, false);
    expect(payload.isCompressed, false);
    expect(payload.mimeType, 'application/pdf');
    expect(payload.bytes, <int>[1, 2, 3]);
  });

  test('GIF 图片跳过压缩并保留原始内容', () async {
    final engine = _TrackingCompressionEngine();
    final service = ImageUploadCompressService(
      engine: engine,
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 100, height: 100),
      readFileBytes: (_) async => Uint8List.fromList(<int>[4, 5, 6]),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/demo.bin',
      mimeType: 'image/gif',
    );

    expect(engine.callCount, 0);
    expect(payload.isImage, true);
    expect(payload.isCompressed, false);
    expect(payload.mimeType, 'image/gif');
    expect(payload.bytes, <int>[4, 5, 6]);
  });

  test('SVG 图片跳过压缩并保留原始内容', () async {
    final engine = _TrackingCompressionEngine();
    final service = ImageUploadCompressService(
      engine: engine,
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 100, height: 100),
      readFileBytes: (_) async => Uint8List.fromList(<int>[7, 8, 9]),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/vector.bin',
      mimeType: 'image/svg+xml',
    );

    expect(engine.callCount, 0);
    expect(payload.isImage, true);
    expect(payload.isCompressed, false);
    expect(payload.mimeType, 'image/svg+xml');
    expect(payload.bytes, <int>[7, 8, 9]);
  });

  test('多轮压缩后仍超限时返回最后一轮结果', () async {
    final service = ImageUploadCompressService(
      engine: _SequenceCompressionEngine(<Uint8List>[
        Uint8List(ImageUploadCompressService.maxUploadImageSize + 100),
        Uint8List(ImageUploadCompressService.maxUploadImageSize + 50),
      ]),
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 4000, height: 3000),
      readFileBytes: (_) async =>
          Uint8List(ImageUploadCompressService.maxUploadImageSize + 500),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/demo.jpg',
      mimeType: 'image/jpeg',
    );

    expect(payload.isImage, true);
    expect(payload.isCompressed, true);
    expect(payload.mimeType, 'image/jpeg');
    expect(payload.exceedsMaxSizeLimit, true);
    expect(
      payload.fileSize,
      ImageUploadCompressService.maxUploadImageSize + 50,
    );
  });

  test('压缩引擎抛异常时回退原始内容', () async {
    final service = ImageUploadCompressService(
      engine: _ThrowingCompressionEngine(),
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 4000, height: 3000),
      readFileBytes: (_) async => Uint8List.fromList(<int>[1, 3, 5, 7]),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/demo.jpg',
      mimeType: 'image/jpeg',
    );

    expect(payload.isImage, true);
    expect(payload.isCompressed, false);
    expect(payload.mimeType, 'image/jpeg');
    expect(payload.fileSize, 4);
    expect(payload.bytes, <int>[1, 3, 5, 7]);
  });

  test('PNG 图片压缩后保留 image/png MIME 并使用 PNG 输出格式', () async {
    final engine = _RecordingCompressionEngine(
      resultBytes: Uint8List.fromList(<int>[8, 6, 7, 5, 3, 0, 9]),
    );
    final service = ImageUploadCompressService(
      engine: engine,
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 4000, height: 3000),
      readFileBytes: (_) async => Uint8List.fromList(<int>[1, 2, 3, 4, 5]),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/demo.png',
      mimeType: 'image/png',
    );

    expect(engine.callCount, 1);
    expect(engine.lastFormat, CompressFormat.png);
    expect(payload.isImage, true);
    expect(payload.isCompressed, true);
    expect(payload.mimeType, 'image/png');
    expect(payload.bytes, <int>[8, 6, 7, 5, 3, 0, 9]);
  });

  test('WEBP 图片保守跳过压缩并保留原始内容', () async {
    final engine = _TrackingCompressionEngine();
    final service = ImageUploadCompressService(
      engine: engine,
      readImageInfo: (_) async =>
          const ImageInfoForCompress(width: 2000, height: 1200),
      readFileBytes: (_) async => Uint8List.fromList(<int>[2, 4, 6, 8]),
    );

    final payload = await service.prepareForUpload(
      filePath: '/tmp/demo.webp',
      mimeType: 'image/webp',
    );

    expect(engine.callCount, 0);
    expect(payload.isImage, true);
    expect(payload.isCompressed, false);
    expect(payload.mimeType, 'image/webp');
    expect(payload.bytes, <int>[2, 4, 6, 8]);
  });
}

class _FakeCompressionEngine implements ImageCompressionEngine {
  @override
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    return Uint8List.fromList(<int>[9, 9, 9]);
  }
}

class _SequenceCompressionEngine implements ImageCompressionEngine {
  _SequenceCompressionEngine(this.outputs);

  final List<Uint8List> outputs;
  int _index = 0;

  @override
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    if (_index >= outputs.length) {
      return outputs.last;
    }
    return outputs[_index++];
  }
}

class _TrackingCompressionEngine implements ImageCompressionEngine {
  int callCount = 0;

  @override
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    callCount += 1;
    return Uint8List.fromList(<int>[9, 9, 9]);
  }
}

class _ThrowingCompressionEngine implements ImageCompressionEngine {
  @override
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) {
    throw StateError('compression failed');
  }
}

class _RecordingCompressionEngine implements ImageCompressionEngine {
  _RecordingCompressionEngine({required this.resultBytes});

  final Uint8List resultBytes;
  int callCount = 0;
  CompressFormat? lastFormat;

  @override
  Future<Uint8List?> compress({
    required String path,
    required CompressFormat format,
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    callCount += 1;
    lastFormat = format;
    return resultBytes;
  }
}
