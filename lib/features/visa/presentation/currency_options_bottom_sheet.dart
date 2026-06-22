import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/selectable_options_bottom_sheet.dart';
import '../data/visa_currency.dart';

Future<VisaCurrency?> showVisaCurrencyOptionsBottomSheet({
  required BuildContext context,
  VisaCurrency initialValue = VisaCurrency.cny,
}) async {
  final List<VisaCurrency>? result =
      await showSelectableOptionsBottomSheet<VisaCurrency>(
        context: context,
        title: '签证编辑.选择货币'.tr(),
        options: VisaCurrency.values
            .map(
              (VisaCurrency currency) => SelectableSheetOption<VisaCurrency>(
                value: currency,
                label: currency.labelKey.tr(),
              ),
            )
            .toList(growable: false),
        initialSelectedValues: <VisaCurrency>[initialValue],
        multiple: false,
      );
  if (result == null || result.isEmpty) {
    return null;
  }
  return result.first;
}
