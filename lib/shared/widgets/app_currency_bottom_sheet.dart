import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../models/app_currency.dart';
import 'selectable_options_bottom_sheet.dart';

Future<AppCurrency?> showAppCurrencyOptionsBottomSheet({
  required BuildContext context,
  AppCurrency initialValue = AppCurrency.cny,
  String? title,
}) async {
  final List<AppCurrency>? result =
      await showSelectableOptionsBottomSheet<AppCurrency>(
        context: context,
        title: title ?? '通用.选择货币'.tr(),
        options: AppCurrency.values
            .map(
              (AppCurrency currency) => SelectableSheetOption<AppCurrency>(
                value: currency,
                label: currency.labelKey.tr(),
              ),
            )
            .toList(growable: false),
        initialSelectedValues: <AppCurrency>[initialValue],
        multiple: false,
      );
  if (result == null || result.isEmpty) {
    return null;
  }
  return result.first;
}
