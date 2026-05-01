typedef JsonMap = Map<String, dynamic>;

JsonMap asJsonMap(dynamic raw) {
  if (raw is JsonMap) {
    return raw;
  }
  if (raw is Map) {
    return raw.cast<String, dynamic>();
  }
  throw FormatException(
    'Expected Map<String, dynamic>, got ${raw.runtimeType}',
  );
}

List<JsonMap> asJsonMapList(dynamic raw) {
  if (raw is! List) {
    throw FormatException('Expected List, got ${raw.runtimeType}');
  }
  return raw.map<JsonMap>(asJsonMap).toList(growable: false);
}

List<T> decodeModelList<T>(dynamic raw, T Function(JsonMap json) fromJson) {
  return asJsonMapList(raw).map<T>(fromJson).toList(growable: false);
}

List<String> decodeStringList(dynamic raw) {
  if (raw is! List) {
    throw FormatException('Expected List, got ${raw.runtimeType}');
  }
  return raw.map((item) => item?.toString() ?? '').toList(growable: false);
}

Map<String, T> decodeMapValues<T>(
  dynamic raw,
  T Function(dynamic value) convert,
) {
  final map = asJsonMap(raw);
  return map.map<String, T>((key, value) => MapEntry(key, convert(value)));
}
