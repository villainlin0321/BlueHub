import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/models/dictionary_models.dart';
import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../data/dictionary_providers.dart';

Future<List<CountryVO>> loadCountries(
  WidgetRef ref, {
  CountrySearchQuery query = const CountrySearchQuery(),
}) async {
  final result = await ref.read(countrySearchProvider(query).future);
  return result.list;
}

List<SelectableSheetOption<String>> buildCountrySheetOptions(
  List<CountryVO> countries,
) {
  final Set<String> seen = <String>{};
  return countries
      .where(
        (item) =>
            item.countryCode.trim().isNotEmpty &&
            item.nameZh.trim().isNotEmpty &&
            seen.add(item.countryCode.trim()),
      )
      .map(
        (item) => SelectableSheetOption<String>(
          value: item.countryCode.trim(),
          label: item.nameZh.trim(),
        ),
      )
      .toList(growable: false);
}

Map<String, String> buildCountryLabelMap(List<CountryVO> countries) {
  return <String, String>{
    for (final CountryVO item in countries)
      if (item.countryCode.trim().isNotEmpty && item.nameZh.trim().isNotEmpty)
        item.countryCode.trim(): item.nameZh.trim(),
  };
}

String resolveCountryCode(String value, List<CountryVO> countries) {
  final String trimmed = value.trim();
  for (final CountryVO item in countries) {
    if (item.countryCode.trim() == trimmed) {
      return trimmed;
    }
    if (item.nameZh.trim() == trimmed) {
      return item.countryCode.trim();
    }
  }
  return trimmed;
}

String resolveCountryLabel(String value, Map<String, String> countryLabelMap) {
  final String trimmed = value.trim();
  return countryLabelMap[trimmed] ?? trimmed;
}

List<String> mapCountryLabelsToCodes(
  Iterable<String> labels,
  List<CountryVO> countries,
) {
  final Map<String, String> codeMap = <String, String>{
    for (final CountryVO item in countries)
      if (item.nameZh.trim().isNotEmpty && item.countryCode.trim().isNotEmpty)
        item.nameZh.trim(): item.countryCode.trim(),
  };
  return labels
      .map((label) => codeMap[label.trim()] ?? label.trim())
      .toSet()
      .toList(growable: false);
}

List<String> mapCountryCodesToLabels(
  Iterable<String> codes,
  Map<String, String> countryLabelMap,
) {
  return codes
      .map((code) => resolveCountryLabel(code, countryLabelMap))
      .toList(growable: false);
}

CountryVO? findCountryByCode(String code, List<CountryVO> countries) {
  final String trimmed = code.trim();
  for (final CountryVO item in countries) {
    if (item.countryCode.trim() == trimmed) {
      return item;
    }
  }
  return null;
}

Future<List<CountryVO>?> showCountryOptionsBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String title,
  Iterable<String> initialSelectedValues = const <String>[],
  bool multiple = true,
  String emptyMessage = '暂无可选国家，请稍后重试',
  String loadFailedMessage = '国家列表加载失败，请稍后重试',
}) async {
  try {
    final List<CountryVO> countries = await loadCountries(ref);
    if (!context.mounted) {
      return null;
    }
    final List<SelectableSheetOption<String>> options =
        buildCountrySheetOptions(countries);
    if (options.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(emptyMessage)));
      return null;
    }
    final Set<String> validValues = options
        .map((SelectableSheetOption<String> item) => item.value)
        .toSet();
    final List<String> normalizedSelected = initialSelectedValues
        .map((value) => resolveCountryCode(value, countries))
        .where(validValues.contains)
        .toList(growable: false);
    final List<String>? result = await showSelectableOptionsBottomSheet<String>(
      context: context,
      title: title,
      options: options,
      initialSelectedValues: normalizedSelected,
      multiple: multiple,
    );
    if (result == null) {
      return null;
    }
    return result
        .map((code) => findCountryByCode(code, countries))
        .whereType<CountryVO>()
        .toList(growable: false);
  } catch (_) {
    if (!context.mounted) {
      return null;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(loadFailedMessage)));
    return null;
  }
}
