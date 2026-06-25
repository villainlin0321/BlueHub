import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/logging/app_logger.dart';
import 'config_models.dart';
import 'tag_dictionary_store.dart';

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService(apiClient: ref.watch(apiClientProvider));
});

final tagDictionaryStoreProvider = Provider<TagDictionaryStore>((ref) {
  return TagDictionaryStore(prefs: ref.watch(sharedPreferencesProvider));
});

final tagDictionaryCacheControllerProvider =
    Provider<TagDictionaryCacheController>((ref) {
      return TagDictionaryCacheController(
        service: ref.watch(configServiceProvider),
        store: ref.watch(tagDictionaryStoreProvider),
      );
    });

final tagDictionaryProvider =
    FutureProvider.family<List<TagItemVO>, TagCategory>((ref, category) async {
      final List<TagItemVO> tags = await ref
          .read(tagDictionaryCacheControllerProvider)
          .getTagsForCategory(category);
      return tags;
    });

class TagDictionaryCacheController {
  const TagDictionaryCacheController({
    required ConfigService service,
    required TagDictionaryStore store,
  }) : _service = service,
       _store = store;

  final ConfigService _service;
  final TagDictionaryStore _store;

  TagDictVO? loadCached() => _store.load();

  Future<void> refreshAll() async {
    try {
      final TagDictVO response = await _service.getTags();
      await _store.save(response);
      AppLogger.instance.info(
        'CONFIG',
        '标签字典缓存刷新成功',
        context: <String, Object?>{'categoryCount': response.tags.length},
      );
    } catch (error, stackTrace) {
      AppLogger.instance.error(
        'CONFIG',
        '标签字典缓存刷新失败',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<TagItemVO>> getTagsForCategory(TagCategory category) async {
    final TagDictVO? cached = loadCached();
    final List<TagItemVO>? cachedTags = cached?.tags[category.value];
    if (cachedTags != null && cachedTags.isNotEmpty) {
      return _sortTags(cachedTags);
    }

    final TagDictVO response = await _service.getTags();
    await _store.save(response);
    return _sortTags(response.tags[category.value] ?? const <TagItemVO>[]);
  }

  List<TagItemVO> _sortTags(List<TagItemVO> tags) {
    return List<TagItemVO>.from(tags)
      ..sort((TagItemVO a, TagItemVO b) => a.sortOrder.compareTo(b.sortOrder));
  }
}
