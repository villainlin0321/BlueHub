import 'package:bluehub_app/shared/network/api_decoders.dart';

enum FileScene {
  avatar('avatar'),
  material('material'),
  cert('cert'),
  review('review'),
  chat('chat'),
  packageCover('package_cover'),
  idCard('id_card'),
  visaDoc('visa_doc');

  const FileScene(this.value);

  final String value;

  static FileScene fromValue(String value) {
    return FileScene.values.firstWhere(
      (FileScene scene) => scene.value == value,
      orElse: () =>
          throw ArgumentError.value(value, 'scene', 'Unsupported file scene'),
    );
  }
}

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
      fileId: readInt(json, 'fileId'),
      objectKey: readString(json, 'objectKey'),
      fileSize: readInt(json, 'fileSize'),
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
  final FileScene scene;
  final String accessType;

  factory FilePresignBO.fromJson(JsonMap json) {
    return FilePresignBO(
      fileName: readString(json, 'fileName'),
      fileType: readString(json, 'fileType'),
      fileSize: readInt(json, 'fileSize'),
      scene: FileScene.fromValue(readString(json, 'scene')),
      accessType: readString(json, 'accessType'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'fileName': fileName,
      'fileType': fileType,
      'fileSize': fileSize,
      'scene': scene.value,
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
      uploadUrl: readString(json, 'uploadUrl'),
      fileUrl: readString(json, 'fileUrl'),
      expireIn: readInt(json, 'expireIn'),
      objectKey: readString(json, 'objectKey'),
      fileId: readInt(json, 'fileId'),
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
