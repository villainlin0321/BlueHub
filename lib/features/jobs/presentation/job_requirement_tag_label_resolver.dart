import 'package:flutter/widgets.dart';

import '../../../shared/localization/app_locales.dart';
import '../../config/data/config_models.dart';
import '../data/job_models.dart';

Map<String, TagItemVO> buildRequirementTagLookup(Iterable<TagItemVO> tags) {
  final Map<String, TagItemVO> lookup = <String, TagItemVO>{};

  void addKey(String value, TagItemVO item) {
    final String key = _normalizeRequirementTagKey(value);
    if (key.isEmpty || lookup.containsKey(key)) {
      return;
    }
    lookup[key] = item;
  }

  for (final TagItemVO item in tags) {
    addKey(item.tagCode, item);
    addKey(item.tagNameZh, item);
    addKey(item.tagNameEn, item);
  }

  return lookup;
}

String resolveRequirementTagLabel(
  BuildContext context,
  TagVO tag,
  Map<String, TagItemVO> requirementTagLookup,
) {
  final String rawLabel = tag.label.trim();
  if (rawLabel.isEmpty) {
    return '';
  }

  final TagItemVO? matched =
      requirementTagLookup[_normalizeRequirementTagKey(rawLabel)];
  if (matched == null) {
    return rawLabel;
  }

  return resolveLocalizedTagItemLabel(context, matched);
}

String resolveLocalizedTagItemLabel(BuildContext context, TagItemVO item) {
  if (context.isChineseLocale) {
    final String zh = item.tagNameZh.trim();
    if (zh.isNotEmpty) {
      return zh;
    }
    final String en = item.tagNameEn.trim();
    return en.isNotEmpty ? en : item.tagCode.trim();
  }

  final String en = item.tagNameEn.trim();
  if (en.isNotEmpty) {
    return en;
  }
  final String zh = item.tagNameZh.trim();
  return zh.isNotEmpty ? zh : item.tagCode.trim();
}

String _normalizeRequirementTagKey(String value) {
  return value.trim().toLowerCase();
}
