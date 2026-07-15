import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/token_store.dart';
import '../localization/app_language_store.dart';
import 'api_client.dart';
import 'app_config.dart';
import 'dio_factory.dart';
import 'sse_client.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore.inMemory();
});

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider 尚未在 ProviderScope 中注入');
});

final appLanguageStoreProvider = Provider<AppLanguageStore>((ref) {
  return AppLanguageStore(prefs: ref.watch(sharedPreferencesProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  final languageStore = ref.watch(appLanguageStoreProvider);
  return DioFactory(
    config: config,
    tokenStore: tokenStore,
    languageStore: languageStore,
  ).create();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiClient(dio);
});

final sseClientProvider = Provider<SseClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokenStore = ref.watch(tokenStoreProvider);
  return SseClient(baseUrl: config.baseUrl, tokenStore: tokenStore);
});
