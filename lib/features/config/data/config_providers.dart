import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bluehub_app/shared/network/providers.dart';
import '../../../shared/network/services/config_service.dart';
import 'config_models.dart';

final configServiceProvider = Provider<ConfigService>((ref) {
  return ConfigService(apiClient: ref.watch(apiClientProvider));
});

final tagDictionaryProvider =
    FutureProvider.family<List<TagItemVO>, TagCategory>((ref, category) async {
      final TagDictVO response = await ref
          .read(configServiceProvider)
          .getTags(category: category);
      final List<TagItemVO> tags = List<TagItemVO>.from(
        response.tags[category.value] ?? const <TagItemVO>[],
      )..sort((TagItemVO a, TagItemVO b) => a.sortOrder.compareTo(b.sortOrder));
      return tags;
    });
