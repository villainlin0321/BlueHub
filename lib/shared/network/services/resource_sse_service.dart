import 'package:bluehub_app/shared/network/api_client.dart';
import 'package:bluehub_app/shared/network/api_decoders.dart';
import 'package:bluehub_app/shared/network/sse_client.dart';
import 'package:bluehub_app/shared/network/sse_models.dart';
import '../../../features/sse/data/resource_sse_models.dart';

class ResourceSseService {
  ResourceSseService({
    required ApiClient apiClient,
    required SseClient sseClient,
  }) : _apiClient = apiClient,
       _sseClient = sseClient;

  final ApiClient _apiClient;
  final SseClient _sseClient;

  Stream<SseEvent> connectResourceStream() {
    return _sseClient.connect('/resource/sse');
  }

  Future<RVoid> closeResourceStream() async {
    final response = await _apiClient.get<RVoid>(
      '/resource/sse/close',
      decode: (data) => RVoid.fromJson(asJsonMap(data)),
    );
    return response;
  }
}
