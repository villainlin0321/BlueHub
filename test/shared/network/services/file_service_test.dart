import 'dart:io';

import 'package:dio/dio.dart';
import 'package:europepass/features/files/data/file_models.dart';
import 'package:europepass/shared/network/api_client.dart';
import 'package:europepass/shared/network/services/file_service.dart';
import 'package:europepass/shared/network/services/image_upload_compress_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('非图片上传沿用原始 mimeType 和 fileSize', () async {
    final File file = await File(
      '${Directory.systemTemp.path}/file-service-upload.txt',
    ).create();
    await file.writeAsBytes(<int>[1, 2, 3, 4]);

    final _RecordingFileService service = _RecordingFileService(
      apiClient: _NoopApiClient(),
      imageUploadCompressService: _FakeImageUploadCompressService(
        const PreparedUploadPayload(
          bytes: <int>[1, 2, 3, 4],
          mimeType: 'text/plain',
          fileSize: 4,
          isImage: false,
          isCompressed: false,
          exceedsMaxSizeLimit: false,
        ),
      ),
    );

    await service.uploadFile(
      path: file.path,
      scene: FileScene.chat,
      errorMessage: 'upload failed',
    );

    expect(service.lastPresignRequest?.fileType, 'text/plain');
    expect(service.lastPresignRequest?.fileSize, 4);
    expect(service.lastUploadBytes, <int>[1, 2, 3, 4]);
    expect(service.lastUploadMimeType, 'text/plain');
    expect(service.lastConfirmRequest?.fileSize, 4);
  });

  test('图片上传使用压缩后的 mimeType 和 fileSize', () async {
    final File file = await File(
      '${Directory.systemTemp.path}/file-service-upload.jpg',
    ).create();
    await file.writeAsBytes(List<int>.filled(10, 7));

    final _RecordingFileService service = _RecordingFileService(
      apiClient: _NoopApiClient(),
      imageUploadCompressService: _FakeImageUploadCompressService(
        const PreparedUploadPayload(
          bytes: <int>[9, 9, 9],
          mimeType: 'image/jpeg',
          fileSize: 3,
          isImage: true,
          isCompressed: true,
          exceedsMaxSizeLimit: false,
        ),
      ),
    );

    await service.uploadFile(
      path: file.path,
      scene: FileScene.chat,
      errorMessage: 'upload failed',
    );

    expect(service.lastPresignRequest?.fileType, 'image/jpeg');
    expect(service.lastPresignRequest?.fileSize, 3);
    expect(service.lastUploadBytes, <int>[9, 9, 9]);
    expect(service.lastUploadMimeType, 'image/jpeg');
    expect(service.lastConfirmRequest?.fileSize, 3);
  });
}

class _RecordingFileService extends FileService {
  _RecordingFileService({
    required super.apiClient,
    required super.imageUploadCompressService,
  });

  FilePresignBO? lastPresignRequest;
  ConfirmUploadBO? lastConfirmRequest;
  List<int>? lastUploadBytes;
  String? lastUploadMimeType;

  @override
  Future<FilePresignVO> presign({required FilePresignBO request}) async {
    lastPresignRequest = request;
    return const FilePresignVO(
      uploadUrl: 'https://example.com/upload',
      fileUrl: '',
      expireIn: 300,
      objectKey: 'demo-key',
      fileId: 1,
    );
  }

  @override
  Future<void> putToUploadUrl({
    required String uploadUrl,
    required List<int> bytes,
    required String mimeType,
    String errorMessage = '',
    void Function(int sent, int total)? onSendProgress,
  }) async {
    lastUploadBytes = bytes;
    lastUploadMimeType = mimeType;
  }

  @override
  Future<void> confirmUpload({required ConfirmUploadBO request}) async {
    lastConfirmRequest = request;
  }

  @override
  Future<String> getFileUrl({required int fileId}) async {
    return 'https://example.com/file.jpg';
  }
}

class _NoopApiClient extends ApiClient {
  _NoopApiClient() : super(Dio());
}

class _FakeImageUploadCompressService extends ImageUploadCompressService {
  _FakeImageUploadCompressService(this.payload);

  final PreparedUploadPayload payload;

  @override
  Future<PreparedUploadPayload> prepareForUpload({
    required String filePath,
    required String mimeType,
  }) async {
    return payload;
  }
}
