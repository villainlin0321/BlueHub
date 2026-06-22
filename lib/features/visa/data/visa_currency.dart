enum VisaCurrency {
  cny(symbol: '¥', labelKey: '签证编辑.人民币', legacyCodes: <String>{'CNY', '¥'}),
  eur(symbol: '€', labelKey: '签证编辑.欧元', legacyCodes: <String>{'EUR', '€'});

  const VisaCurrency({
    required this.symbol,
    required this.labelKey,
    required this.legacyCodes,
  });

  final String symbol;
  final String labelKey;
  final Set<String> legacyCodes;

  static VisaCurrency fromApiValue(String? value) {
    final String normalized = value?.trim().toUpperCase() ?? '';
    for (final VisaCurrency currency in VisaCurrency.values) {
      if (currency.legacyCodes.any((String code) => code.toUpperCase() == normalized)) {
        return currency;
      }
    }
    return VisaCurrency.cny;
  }
}
