import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'file_models.dart';

class FileService {
  FileService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<void> confirmUpload({required ConfirmUploadBO request}) async {
    return _apiClient.postVoid('/files/confirm', data: request.toJson());
  }

  Future<FilePresignVO> presign({required FilePresignBO request}) async {
    final response = await _apiClient.post<FilePresignVO>(
      '/files/presign',
      data: request.toJson(),
      decode: (data) => FilePresignVO.fromJson(asJsonMap(data)),
    );
    return response;
  }

  Future<String> getFileUrl({required int fileId}) async {
    final response = await _apiClient.get<String>(
      '/files/$fileId/url',
      decode: (data) => data as String? ?? '',
    );
    return response;
  }
}
