import 'package:bluehub_app/shared/network/api_decoders.dart';

class ConfirmUploadBO {
  const ConfirmUploadBO({
    required this.fileId,
    required this.objectKey,
    required this.fileSize,
  });

  final int fileId;
  final String objectKey;
  final int fileSize;

  factory ConfirmUploadBO.fromJson(JsonMap json) {
    return ConfirmUploadBO(
      fileId: (json['fileId'] as num?)?.toInt() ?? 0,
      objectKey: json['objectKey'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'fileId': fileId,
      'objectKey': objectKey,
      'fileSize': fileSize,
    };
  }
}

class FilePresignBO {
  const FilePresignBO({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.scene,
    required this.accessType,
  });

  final String fileName;
  final String fileType;
  final int fileSize;
  final String scene;
  final String accessType;

  factory FilePresignBO.fromJson(JsonMap json) {
    return FilePresignBO(
      fileName: json['fileName'] as String? ?? '',
      fileType: json['fileType'] as String? ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      scene: json['scene'] as String? ?? '',
      accessType: json['accessType'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'scene': scene,
      'accessType': accessType,
    };
  }
}

class FilePresignVO {
  const FilePresignVO({
    required this.uploadUrl,
    required this.fileUrl,
    required this.expireIn,
    required this.objectKey,
    required this.fileId,
  });

  final String uploadUrl;
  final String fileUrl;
  final int expireIn;
  final String objectKey;
  final int fileId;

  factory FilePresignVO.fromJson(JsonMap json) {
    return FilePresignVO(
      uploadUrl: json['uploadUrl'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? '',
      expireIn: (json['expireIn'] as num?)?.toInt() ?? 0,
      objectKey: json['objectKey'] as String? ?? '',
      fileId: (json['fileId'] as num?)?.toInt() ?? 0,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'uploadUrl': uploadUrl,
      'fileUrl': fileUrl,
      'expireIn': expireIn,
      'objectKey': objectKey,
      'fileId': fileId,
    };
  }
}
