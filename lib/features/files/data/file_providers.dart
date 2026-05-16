import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/file_service.dart';

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService(apiClient: ref.watch(apiClientProvider));
});
