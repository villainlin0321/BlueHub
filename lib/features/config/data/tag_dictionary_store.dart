import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../shared/network/api_decoders.dart';
import 'config_models.dart';

class TagDictionaryStore {
  const TagDictionaryStore({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _storageKey = 'config.tag_dictionary';

  final SharedPreferences _prefs;

  TagDictVO? load() {
    final String raw = _prefs.getString(_storageKey)?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }
    try {
      return TagDictVO.fromJson(asJsonMap(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> save(TagDictVO dictionary) async {
    await _prefs.setString(_storageKey, jsonEncode(dictionary.toJson()));
  }

  Future<void> clear() async {
    await _prefs.remove(_storageKey);
  }
}
