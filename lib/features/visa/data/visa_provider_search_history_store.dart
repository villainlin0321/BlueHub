import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/network/providers.dart';

final visaProviderSearchHistoryStoreProvider =
    Provider<VisaProviderSearchHistoryStore>((ref) {
      return VisaProviderSearchHistoryStore(
        prefs: ref.watch(sharedPreferencesProvider),
      );
    });

class VisaProviderSearchHistoryStore {
  const VisaProviderSearchHistoryStore({required SharedPreferences prefs})
    : _prefs = prefs;

  static const String _historyKey = 'visa_provider_search.history';
  static const int maxHistoryCount = 20;

  final SharedPreferences _prefs;

  List<String> loadHistory() {
    final List<String> stored = _prefs.getStringList(_historyKey) ?? <String>[];
    return stored
        .map((String keyword) => keyword.trim())
        .where((String keyword) => keyword.isNotEmpty)
        .take(maxHistoryCount)
        .toList(growable: false);
  }

  Future<List<String>> saveKeyword(String keyword) async {
    final String normalized = keyword.trim();
    if (normalized.isEmpty) {
      return loadHistory();
    }

    final List<String> nextHistory = <String>[
      normalized,
      ...loadHistory().where((String item) => item != normalized),
    ].take(maxHistoryCount).toList(growable: false);
    await _prefs.setStringList(_historyKey, nextHistory);
    return nextHistory;
  }

  Future<void> clear() async {
    await _prefs.remove(_historyKey);
  }
}
