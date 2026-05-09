typedef JsonMap = Map<String, dynamic>;

/// 把任意动态对象安全转换为 `JsonMap`，结构不合法时返回空对象。
JsonMap asJsonMap(dynamic raw) {
  if (raw is JsonMap) {
    return raw;
  }
  if (raw is Map) {
    try {
      return raw.cast<String, dynamic>();
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
  return const <String, dynamic>{};
}

/// 把任意动态对象安全转换为 `JsonMap` 列表，非法元素会被忽略。
List<JsonMap> asJsonMapList(dynamic raw) {
  if (raw is! List) {
    return const <JsonMap>[];
  }

  final List<JsonMap> result = <JsonMap>[];
  for (final item in raw) {
    final map = asJsonMap(item);
    if (map.isNotEmpty || item is Map) {
      result.add(map);
    }
  }
  return result;
}

/// 安全解析模型数组，单个元素异常时会跳过，避免整组数据解析失败。
List<T> decodeModelList<T>(dynamic raw, T Function(JsonMap json) fromJson) {
  final List<T> result = <T>[];
  for (final item in asJsonMapList(raw)) {
    try {
      result.add(fromJson(item));
    } catch (_) {
      // 单个模型异常不影响其余元素继续解析。
    }
  }
  return result;
}

/// 安全解析字符串数组，兼容数字和布尔值，并忽略复杂结构元素。
List<String> decodeStringList(dynamic raw) {
  if (raw is! List) {
    return const <String>[];
  }
  return raw
      .where((item) => item == null || item is String || item is num || item is bool)
      .map((item) => item?.toString() ?? '')
      .toList(growable: false);
}

/// 安全解析整数数组，兼容数字字符串和浮点值。
List<int> decodeIntList(dynamic raw) {
  if (raw is! List) {
    return const <int>[];
  }

  final List<int> result = <int>[];
  for (final item in raw) {
    if (item is int) {
      result.add(item);
      continue;
    }
    if (item is num) {
      result.add(item.toInt());
      continue;
    }
    if (item is String) {
      final parsed = int.tryParse(item) ?? double.tryParse(item)?.toInt();
      if (parsed != null) {
        result.add(parsed);
      }
    }
  }
  return result;
}

/// 安全读取对象字段中的字符串，兼容数字和布尔类型。
String readString(JsonMap json, String key, {String fallback = ''}) {
  final value = json[key];
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return fallback;
}

/// 安全读取对象字段中的整数，兼容数字字符串和浮点类型。
int readInt(JsonMap json, String key, {int fallback = 0}) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

/// 安全读取对象字段中的浮点数，兼容整型和数字字符串。
double readDouble(JsonMap json, String key, {double fallback = 0}) {
  final value = json[key];
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? fallback;
  }
  return fallback;
}

/// 安全读取对象字段中的布尔值，兼容 `0/1` 与字符串布尔。
bool readBool(JsonMap json, String key, {bool fallback = false}) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'y':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'n':
        return false;
      default:
        return fallback;
    }
  }
  return fallback;
}

/// 安全读取对象字段中的嵌套对象，结构不合法时返回空对象。
JsonMap readJsonMap(JsonMap json, String key) {
  return asJsonMap(json[key]);
}

/// 安全读取对象字段中的字符串数组。
List<String> readStringList(JsonMap json, String key) {
  return decodeStringList(json[key]);
}

/// 安全读取对象字段中的整数数组。
List<int> readIntList(JsonMap json, String key) {
  return decodeIntList(json[key]);
}

/// 安全读取对象字段中的模型数组。
List<T> readModelList<T>(
  JsonMap json,
  String key,
  T Function(JsonMap json) fromJson,
) {
  return decodeModelList<T>(json[key], fromJson);
}

/// 安全解析 Map 值，字段结构异常时返回空映射。
Map<String, T> decodeMapValues<T>(
  dynamic raw,
  T Function(dynamic value) convert,
) {
  final map = asJsonMap(raw);
  return map.map<String, T>((key, value) => MapEntry(key, convert(value)));
}
