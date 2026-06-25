enum AppCurrency {
  cny(
    apiValue: 'CNY',
    symbol: '¥',
    labelKey: '通用.人民币',
    legacyCodes: <String>{'CNY', 'RMB', '¥'},
  ),
  eur(
    apiValue: 'EUR',
    symbol: '€',
    labelKey: '通用.欧元',
    legacyCodes: <String>{'EUR', '€'},
  );

  const AppCurrency({
    required this.apiValue,
    required this.symbol,
    required this.labelKey,
    required this.legacyCodes,
  });

  final String apiValue;
  final String symbol;
  final String labelKey;
  final Set<String> legacyCodes;

  static AppCurrency? tryParse(String? value) {
    final String normalized = value?.trim().toUpperCase() ?? '';
    for (final AppCurrency currency in AppCurrency.values) {
      if (currency.legacyCodes.any(
        (String code) => code.toUpperCase() == normalized,
      )) {
        return currency;
      }
    }
    return null;
  }

  static AppCurrency fromApiValue(
    String? value, {
    AppCurrency fallback = AppCurrency.cny,
  }) {
    return tryParse(value) ?? fallback;
  }

  static String displayPrefixFor(
    String? rawCurrency, {
    AppCurrency fallback = AppCurrency.cny,
  }) {
    final AppCurrency? currency = tryParse(rawCurrency);
    if (currency != null) {
      return currency.symbol;
    }
    final String normalized = rawCurrency?.trim() ?? '';
    if (normalized.isEmpty) {
      return fallback.symbol;
    }
    if (RegExp(r'^[A-Za-z]{3,}$').hasMatch(normalized)) {
      return '${normalized.toUpperCase()} ';
    }
    return normalized;
  }

  static ({String symbol, String value}) buildAmountParts(
    num amount,
    String? rawCurrency, {
    AppCurrency fallback = AppCurrency.cny,
    int fractionDigitsWhenNeeded = 1,
    bool trimTrailingZeros = true,
  }) {
    return (
      symbol: displayPrefixFor(rawCurrency, fallback: fallback),
      value: _formatNumber(
        amount,
        fractionDigitsWhenNeeded: fractionDigitsWhenNeeded,
        trimTrailingZeros: trimTrailingZeros,
      ),
    );
  }

  static String formatAmount(
    num amount,
    String? rawCurrency, {
    AppCurrency fallback = AppCurrency.cny,
    int fractionDigitsWhenNeeded = 1,
    bool trimTrailingZeros = true,
  }) {
    final ({String symbol, String value}) parts = buildAmountParts(
      amount,
      rawCurrency,
      fallback: fallback,
      fractionDigitsWhenNeeded: fractionDigitsWhenNeeded,
      trimTrailingZeros: trimTrailingZeros,
    );
    return '${parts.symbol}${parts.value}';
  }

  static String formatRange({
    required num min,
    required num max,
    required String? rawCurrency,
    String? period,
    AppCurrency fallback = AppCurrency.cny,
    int fractionDigitsWhenNeeded = 1,
    bool trimTrailingZeros = true,
  }) {
    if (min <= 0 && max <= 0) {
      return '';
    }
    final String prefix = displayPrefixFor(rawCurrency, fallback: fallback);
    final num effectiveMin = min > 0 ? min : max;
    final String minText = _formatNumber(
      effectiveMin,
      fractionDigitsWhenNeeded: fractionDigitsWhenNeeded,
      trimTrailingZeros: trimTrailingZeros,
    );
    final String rangeText = max > 0 && max != effectiveMin
        ? '$prefix$minText~${_formatNumber(
            max,
            fractionDigitsWhenNeeded: fractionDigitsWhenNeeded,
            trimTrailingZeros: trimTrailingZeros,
          )}'
        : '$prefix$minText';
    final String normalizedPeriod = period?.trim() ?? '';
    return normalizedPeriod.isEmpty ? rangeText : '$rangeText/$normalizedPeriod';
  }

  static String _formatNumber(
    num amount, {
    required int fractionDigitsWhenNeeded,
    required bool trimTrailingZeros,
  }) {
    final double value = amount.toDouble();
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    final String text = value.toStringAsFixed(fractionDigitsWhenNeeded);
    if (!trimTrailingZeros) {
      return text;
    }
    return text.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
