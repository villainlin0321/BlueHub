import 'dart:io';

const String _testStyleImport =
    "import 'package:europepass/shared/ui/test_style.dart';";

const Set<String> _supportedKeys = <String>{
  'fontSize',
  'color',
  'fontWeight',
  'fontFamily',
  'letterSpacing',
  'decoration',
  'fontStyle',
  'overflow',
  'backgroundColor',
  'height',
};

final RegExp _weightPattern = RegExp(r'FontWeight\.(w\d{3}|bold)');
final RegExp _themeCopyWithPattern = RegExp(
  r'Theme\.of\(context\)\.textTheme\.([A-Za-z0-9_]+)\?*\.copyWith\(',
);
final RegExp _chinesePattern = RegExp(r'[\u4e00-\u9fff]');
final RegExp _numberContextPattern = RegExp(
  r'price|amount|total|count|score|rating|¥|\$|￥|\d',
  caseSensitive: false,
);

const Map<String, _ThemeTextSpec> _themeTextSpecs = <String, _ThemeTextSpec>{
  'bodySmall': _ThemeTextSpec(fontSize: 12, fontWeight: 400),
  'bodyMedium': _ThemeTextSpec(fontSize: 14, fontWeight: 400),
  'bodyLarge': _ThemeTextSpec(fontSize: 16, fontWeight: 400),
  'labelSmall': _ThemeTextSpec(fontSize: 11, fontWeight: 500),
  'labelMedium': _ThemeTextSpec(fontSize: 12, fontWeight: 500),
  'labelLarge': _ThemeTextSpec(fontSize: 14, fontWeight: 500),
  'titleSmall': _ThemeTextSpec(fontSize: 14, fontWeight: 500),
  'titleMedium': _ThemeTextSpec(fontSize: 16, fontWeight: 500),
  'titleLarge': _ThemeTextSpec(fontSize: 22, fontWeight: 400),
  'headlineSmall': _ThemeTextSpec(fontSize: 24, fontWeight: 400),
  'headlineMedium': _ThemeTextSpec(fontSize: 28, fontWeight: 400),
  'headlineLarge': _ThemeTextSpec(fontSize: 32, fontWeight: 400),
  'displaySmall': _ThemeTextSpec(fontSize: 36, fontWeight: 400),
  'displayMedium': _ThemeTextSpec(fontSize: 45, fontWeight: 400),
  'displayLarge': _ThemeTextSpec(fontSize: 57, fontWeight: 400),
};

void main(List<String> args) {
  final bool apply = args.contains('--apply');
  final bool reportOnly = !apply || args.contains('--report');
  final String scope = _readOption(args, '--scope') ?? 'lib';
  final Directory root = Directory.current;
  final String scopePath = _normalizeScope(root, scope);
  final List<File> files = _resolveScopeFiles(scopePath);

  if (files.isEmpty) {
    stderr.writeln('Scope not found or empty: $scopePath');
    exitCode = 2;
    return;
  }

  final List<FileReport> reports = <FileReport>[];
  int scannedCount = 0;
  int replacedCount = 0;

  for (final File file in files) {
    final String original = file.readAsStringSync();
    final ScanResult result = _scanFile(file.path, original);
    if (result.records.isEmpty) {
      continue;
    }
    scannedCount += result.records.length;

    if (apply &&
        result.updatedContent != null &&
        result.updatedContent != original) {
      file.writeAsStringSync(result.updatedContent!);
      replacedCount += result.replacedCount;
    }

    reports.add(
      FileReport(
        path: file.path,
        records: result.records,
        replacedCount: result.replacedCount,
      ),
    );
  }

  if (reportOnly) {
    for (final FileReport report in reports) {
      stdout.writeln(report.summaryLine);
      for (final StyleRecord record in report.records) {
        stdout.writeln(
          '  - line ${record.line}: '
          'source=${record.sourceType}, '
          'height=${record.hasHeight ? 'yes' : 'no'}, '
          'fontFamily=${record.hasFontFamily ? 'yes' : 'no'}, '
          'factory=${record.suggestedFactory ?? '-'}, '
          'status=${record.status}',
        );
      }
    }
  }

  stdout.writeln(
    'Done. files=${reports.length}, scanned=$scannedCount, replaced=$replacedCount, '
    'mode=${apply ? 'apply' : 'report'}, scope=$scopePath',
  );
}

List<File> _resolveScopeFiles(String scopePath) {
  final File file = File(scopePath);
  if (file.existsSync()) {
    return file.path.endsWith('.dart') ? <File>[file] : <File>[];
  }

  final Directory directory = Directory(scopePath);
  if (!directory.existsSync()) {
    return <File>[];
  }

  final List<File> files =
      directory
          .listSync(recursive: true)
          .whereType<File>()
          .where((File candidate) => candidate.path.endsWith('.dart'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));
  return files;
}

String _normalizeScope(Directory root, String scope) {
  if (scope.startsWith('/')) {
    return scope;
  }
  return '${root.path}${Platform.pathSeparator}$scope';
}

String? _readOption(List<String> args, String key) {
  for (final String arg in args) {
    if (arg.startsWith('$key=')) {
      return arg.substring(key.length + 1);
    }
  }
  return null;
}

ScanResult _scanFile(String path, String content) {
  final _IntermediateScanResult themeResult = _scanThemeCopyWiths(content);
  final String contentAfterTheme = themeResult.updatedContent ?? content;

  final _IntermediateScanResult textStyleResult = _scanTextStyles(
    contentAfterTheme,
  );
  final List<StyleRecord> records = <StyleRecord>[
    ...themeResult.records,
    ...textStyleResult.records,
  ];
  final int replacedCount =
      themeResult.replacedCount + textStyleResult.replacedCount;

  if (records.isEmpty) {
    return const ScanResult(records: <StyleRecord>[], replacedCount: 0);
  }

  String? updatedContent;
  if (replacedCount > 0) {
    updatedContent = _ensureImport(
      _rewriteConstTextStyleDeclarations(
        textStyleResult.updatedContent ?? contentAfterTheme,
      ),
    );
  }

  return ScanResult(
    records: records,
    replacedCount: replacedCount,
    updatedContent: updatedContent,
  );
}

_IntermediateScanResult _scanThemeCopyWiths(String content) {
  final List<_ThemeStyleOccurrence> occurrences = _findThemeOccurrences(
    content,
  );
  if (occurrences.isEmpty) {
    return const _IntermediateScanResult(
      records: <StyleRecord>[],
      replacedCount: 0,
    );
  }

  final StringBuffer updated = StringBuffer();
  final List<StyleRecord> records = <StyleRecord>[];
  int cursor = 0;
  int replacedCount = 0;

  for (final _ThemeStyleOccurrence occurrence in occurrences) {
    final StyleAnalysis analysis = _analyzeThemeOccurrence(content, occurrence);
    records.add(
      StyleRecord(
        line: _lineNumberAt(content, occurrence.fullStart),
        hasHeight: analysis.properties.containsKey('height'),
        hasFontFamily: analysis.properties.containsKey('fontFamily'),
        suggestedFactory: analysis.factory,
        sourceType: 'theme.copyWith',
        status: analysis.replacement == null ? 'skipped' : 'replaceable',
      ),
    );

    updated.write(content.substring(cursor, occurrence.fullStart));
    if (analysis.replacement != null) {
      updated.write(analysis.replacement);
      replacedCount++;
    } else {
      updated.write(content.substring(occurrence.fullStart, occurrence.end));
    }
    cursor = occurrence.end;
  }
  updated.write(content.substring(cursor));

  return _IntermediateScanResult(
    records: records,
    replacedCount: replacedCount,
    updatedContent: replacedCount > 0 ? updated.toString() : null,
  );
}

_IntermediateScanResult _scanTextStyles(String content) {
  final List<_StyleOccurrence> occurrences = _findOccurrences(content);
  if (occurrences.isEmpty) {
    return const _IntermediateScanResult(
      records: <StyleRecord>[],
      replacedCount: 0,
    );
  }

  final StringBuffer updated = StringBuffer();
  final List<StyleRecord> records = <StyleRecord>[];
  int cursor = 0;
  int replacedCount = 0;

  for (final _StyleOccurrence occurrence in occurrences) {
    final StyleAnalysis analysis = _analyzeOccurrence(content, occurrence);
    records.add(
      StyleRecord(
        line: _lineNumberAt(content, occurrence.start),
        hasHeight: analysis.properties.containsKey('height'),
        hasFontFamily: analysis.properties.containsKey('fontFamily'),
        suggestedFactory: analysis.factory,
        sourceType: 'TextStyle',
        status: analysis.replacement == null ? 'skipped' : 'replaceable',
      ),
    );

    updated.write(content.substring(cursor, occurrence.fullStart));
    if (analysis.replacement != null) {
      updated.write(analysis.replacement);
      replacedCount++;
    } else {
      updated.write(content.substring(occurrence.fullStart, occurrence.end));
    }
    cursor = occurrence.end;
  }
  updated.write(content.substring(cursor));

  return _IntermediateScanResult(
    records: records,
    replacedCount: replacedCount,
    updatedContent: replacedCount > 0 ? updated.toString() : null,
  );
}

int _findMatchingParen(String content, int openParenIndex) {
  int depth = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;

  for (int i = openParenIndex; i < content.length; i++) {
    final String char = content[i];
    final String prev = i > 0 ? content[i - 1] : '';

    if (char == "'" && !inDoubleQuote && prev != r'\') {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && !inSingleQuote && prev != r'\') {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (inSingleQuote || inDoubleQuote) {
      continue;
    }

    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}

StyleAnalysis _analyzeThemeOccurrence(
  String content,
  _ThemeStyleOccurrence occurrence,
) {
  final String snippet = content.substring(
    occurrence.copyWithStart,
    occurrence.end,
  );
  final int bodyStart = snippet.indexOf('(');
  final String body = snippet.substring(bodyStart + 1, snippet.length - 1);
  final Map<String, String> properties = _parseProperties(body);
  if (properties.keys.any((String key) => !_supportedKeys.contains(key))) {
    return StyleAnalysis(properties: properties);
  }

  final _ThemeTextSpec? themeSpec = _themeTextSpecs[occurrence.themeSlot];
  if (themeSpec == null) {
    return StyleAnalysis(properties: properties);
  }

  final Map<String, String> effectiveProperties = <String, String>{
    ...properties,
    'fontSize': properties['fontSize'] ?? themeSpec.fontSizeLabel,
    'fontWeight': properties['fontWeight'] ?? themeSpec.fontWeightLabel,
  };

  final String context = _contextWindow(
    content,
    occurrence.fullStart,
    occurrence.end,
  );
  final String? factory = _selectFactory(effectiveProperties, context);
  if (factory == null) {
    return StyleAnalysis(properties: properties);
  }

  final List<String> args = <String>[
    'fontSize: ${effectiveProperties['fontSize']}',
  ];
  const List<String> orderedKeys = <String>[
    'color',
    'letterSpacing',
    'decoration',
    'fontStyle',
    'overflow',
    'backgroundColor',
  ];
  for (final String key in orderedKeys) {
    final String? value = properties[key];
    if (value != null) {
      args.add('$key: $value');
    }
  }

  return StyleAnalysis(
    properties: properties,
    factory: factory,
    replacement: 'TestStyle.$factory(${args.join(', ')})',
  );
}

StyleAnalysis _analyzeOccurrence(String content, _StyleOccurrence occurrence) {
  final String snippet = content.substring(occurrence.start, occurrence.end);
  final int bodyStart = snippet.indexOf('(');
  final String body = snippet.substring(bodyStart + 1, snippet.length - 1);
  final Map<String, String> properties = _parseProperties(body);

  if (properties.isEmpty) {
    return StyleAnalysis(properties: properties);
  }
  if (properties.keys.any((String key) => !_supportedKeys.contains(key))) {
    return StyleAnalysis(properties: properties);
  }

  final String context = _contextWindow(
    content,
    occurrence.fullStart,
    occurrence.end,
  );
  final String? factory = _selectFactory(properties, context);
  if (factory == null) {
    return StyleAnalysis(properties: properties);
  }

  final List<String> args = <String>[];
  final String? fontSize = properties['fontSize'];
  if (fontSize != null) {
    args.add('fontSize: $fontSize');
  }
  const List<String> orderedKeys = <String>[
    'color',
    'letterSpacing',
    'decoration',
    'fontStyle',
    'overflow',
    'backgroundColor',
  ];
  for (final String key in orderedKeys) {
    final String? value = properties[key];
    if (value != null) {
      args.add('$key: $value');
    }
  }

  return StyleAnalysis(
    properties: properties,
    factory: factory,
    replacement: 'TestStyle.$factory(${args.join(', ')})',
  );
}

String _ensureImport(String content) {
  if (content.contains(_testStyleImport)) {
    return content;
  }

  final RegExp importPattern = RegExp(
    r'''^import\s+['"].+['"];\s*$''',
    multiLine: true,
  );
  final Iterable<RegExpMatch> matches = importPattern.allMatches(content);
  if (matches.isNotEmpty) {
    final RegExpMatch lastMatch = matches.last;
    return content.replaceRange(
      lastMatch.end,
      lastMatch.end,
      '\n$_testStyleImport',
    );
  }

  return '$_testStyleImport\n\n$content';
}

String _rewriteConstTextStyleDeclarations(String content) {
  final RegExp declarationPattern = RegExp(
    r'((?:static\s+)?)const(\s+TextStyle\s+\w+\s*=\s*TestStyle\.)',
  );
  return content.replaceAllMapped(declarationPattern, (Match match) {
    final String staticPrefix = match.group(1) ?? '';
    final String remainder = match.group(2) ?? '';
    return '${staticPrefix}final$remainder';
  });
}

List<_ThemeStyleOccurrence> _findThemeOccurrences(String content) {
  final List<_ThemeStyleOccurrence> occurrences = <_ThemeStyleOccurrence>[];
  for (final RegExpMatch match in _themeCopyWithPattern.allMatches(content)) {
    final int openParenIndex = match.end - 1;
    final int end = _findMatchingParen(content, openParenIndex);
    if (end == -1) {
      continue;
    }
    occurrences.add(
      _ThemeStyleOccurrence(
        fullStart: match.start,
        copyWithStart: openParenIndex - 'copyWith'.length,
        end: end + 1,
        themeSlot: match.group(1)!,
      ),
    );
  }
  return occurrences;
}

List<_StyleOccurrence> _findOccurrences(String content) {
  final List<_StyleOccurrence> occurrences = <_StyleOccurrence>[];
  int index = 0;
  while (index < content.length) {
    final int textStyleIndex = content.indexOf('TextStyle(', index);
    if (textStyleIndex == -1) {
      break;
    }

    int fullStart = textStyleIndex;
    final String before = content.substring(0, textStyleIndex).trimRight();
    if (before.endsWith('const')) {
      fullStart = before.length - 'const'.length;
    }

    final int end = _findMatchingParen(
      content,
      textStyleIndex + 'TextStyle'.length,
    );
    if (end == -1) {
      index = textStyleIndex + 'TextStyle('.length;
      continue;
    }

    occurrences.add(
      _StyleOccurrence(
        fullStart: fullStart,
        start: textStyleIndex,
        end: end + 1,
      ),
    );
    index = end + 1;
  }
  return occurrences;
}

Map<String, String> _parseProperties(String body) {
  final Map<String, String> properties = <String, String>{};
  final List<String> segments = _splitTopLevel(body);
  for (final String segment in segments) {
    final int colonIndex = _indexOfTopLevelColon(segment);
    if (colonIndex == -1) {
      continue;
    }
    final String key = segment.substring(0, colonIndex).trim();
    final String value = segment.substring(colonIndex + 1).trim();
    if (key.isEmpty || value.isEmpty) {
      continue;
    }
    properties[key] = value;
  }
  return properties;
}

List<String> _splitTopLevel(String value) {
  final List<String> result = <String>[];
  final StringBuffer current = StringBuffer();
  int parenDepth = 0;
  int bracketDepth = 0;
  int braceDepth = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;

  for (int i = 0; i < value.length; i++) {
    final String char = value[i];
    final String prev = i > 0 ? value[i - 1] : '';

    if (char == "'" && !inDoubleQuote && prev != r'\') {
      inSingleQuote = !inSingleQuote;
      current.write(char);
      continue;
    }
    if (char == '"' && !inSingleQuote && prev != r'\') {
      inDoubleQuote = !inDoubleQuote;
      current.write(char);
      continue;
    }
    if (!inSingleQuote && !inDoubleQuote) {
      if (char == '(') {
        parenDepth++;
      } else if (char == ')') {
        parenDepth--;
      } else if (char == '[') {
        bracketDepth++;
      } else if (char == ']') {
        bracketDepth--;
      } else if (char == '{') {
        braceDepth++;
      } else if (char == '}') {
        braceDepth--;
      } else if (char == ',' &&
          parenDepth == 0 &&
          bracketDepth == 0 &&
          braceDepth == 0) {
        final String item = current.toString().trim();
        if (item.isNotEmpty) {
          result.add(item);
        }
        current.clear();
        continue;
      }
    }

    current.write(char);
  }

  final String tail = current.toString().trim();
  if (tail.isNotEmpty) {
    result.add(tail);
  }
  return result;
}

int _indexOfTopLevelColon(String value) {
  int parenDepth = 0;
  int bracketDepth = 0;
  int braceDepth = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;

  for (int i = 0; i < value.length; i++) {
    final String char = value[i];
    final String prev = i > 0 ? value[i - 1] : '';

    if (char == "'" && !inDoubleQuote && prev != r'\') {
      inSingleQuote = !inSingleQuote;
      continue;
    }
    if (char == '"' && !inSingleQuote && prev != r'\') {
      inDoubleQuote = !inDoubleQuote;
      continue;
    }
    if (inSingleQuote || inDoubleQuote) {
      continue;
    }

    if (char == '(') {
      parenDepth++;
    } else if (char == ')') {
      parenDepth--;
    } else if (char == '[') {
      bracketDepth++;
    } else if (char == ']') {
      bracketDepth--;
    } else if (char == '{') {
      braceDepth++;
    } else if (char == '}') {
      braceDepth--;
    } else if (char == ':' &&
        parenDepth == 0 &&
        bracketDepth == 0 &&
        braceDepth == 0) {
      return i;
    }
  }
  return -1;
}

String? _selectFactory(Map<String, String> properties, String context) {
  final String? fontFamily = _normalizeFontFamily(properties['fontFamily']);
  final String? fontWeight = properties['fontWeight'];
  final bool hasChineseContext = _chinesePattern.hasMatch(context);
  final bool hasNumericContext = _numberContextPattern.hasMatch(context);
  final String? explicitFamilyFactory = _selectFactoryByFamily(
    fontFamily: fontFamily,
    fontWeight: fontWeight,
  );
  if (explicitFamilyFactory != null) {
    return explicitFamilyFactory;
  }

  if (fontWeight == null) {
    return hasChineseContext ? 'pingFangRegular' : 'regular';
  }

  final Match? match = _weightPattern.firstMatch(fontWeight);
  if (match == null) {
    return null;
  }

  final String token = match.group(1)!;
  final int weight = token == 'bold' ? 700 : int.parse(token.substring(1));

  if (weight >= 700 && hasNumericContext) {
    return 'numberBold';
  }
  if (weight >= 700 && hasChineseContext) {
    return 'bannerBold';
  }
  if (weight >= 700) {
    return 'bold';
  }
  if (weight >= 600) {
    return hasChineseContext ? 'pingFangSemibold' : 'semibold';
  }
  if (weight >= 500) {
    return hasChineseContext ? 'pingFangMedium' : 'medium';
  }
  return hasChineseContext ? 'pingFangRegular' : 'regular';
}

String? _normalizeFontFamily(String? fontFamily) {
  if (fontFamily == null) {
    return null;
  }

  final String normalized = fontFamily
      .replaceAll("'", '')
      .replaceAll('"', '')
      .trim();
  switch (normalized) {
    case 'SF UI Text':
    case 'SFUIText':
    case 'TestStyle.sfUiTextFamily':
      return TestStyleFamily.sfUiText;
    case 'PingFang':
    case 'TestStyle.pingFangFamily':
      return TestStyleFamily.pingFang;
    case 'MiSansLatinVF':
    case 'TestStyle.miSansLatinFamily':
      return TestStyleFamily.miSansLatin;
    case 'AlibabaPuHuiTi':
    case 'TestStyle.alibabaPuHuiTiFamily':
      return TestStyleFamily.alibabaPuHuiTi;
  }
  return null;
}

String? _selectFactoryByFamily({
  required String? fontFamily,
  required String? fontWeight,
}) {
  if (fontFamily == null) {
    return null;
  }

  final int weight = _resolveWeight(fontWeight);
  switch (fontFamily) {
    case TestStyleFamily.sfUiText:
      if (weight >= 700) {
        return 'bold';
      }
      if (weight >= 600) {
        return 'semibold';
      }
      if (weight >= 500) {
        return 'medium';
      }
      return 'regular';
    case TestStyleFamily.pingFang:
      if (weight >= 600) {
        return 'pingFangSemibold';
      }
      if (weight >= 500) {
        return 'pingFangMedium';
      }
      return 'pingFangRegular';
    case TestStyleFamily.miSansLatin:
      return weight >= 700 ? 'numberBold' : 'numberRegular';
    case TestStyleFamily.alibabaPuHuiTi:
      return 'bannerBold';
  }
  return null;
}

int _resolveWeight(String? fontWeight) {
  if (fontWeight == null) {
    return 400;
  }

  final Match? match = _weightPattern.firstMatch(fontWeight);
  if (match == null) {
    return 400;
  }

  final String token = match.group(1)!;
  return token == 'bold' ? 700 : int.parse(token.substring(1));
}

String _contextWindow(String content, int start, int end) {
  final int windowStart = start - 160 < 0 ? 0 : start - 160;
  final int windowEnd = end + 160 > content.length ? content.length : end + 160;
  return content.substring(windowStart, windowEnd);
}

int _lineNumberAt(String content, int index) {
  int line = 1;
  for (int i = 0; i < index; i++) {
    if (content.codeUnitAt(i) == 10) {
      line++;
    }
  }
  return line;
}

class ScanResult {
  const ScanResult({
    required this.records,
    required this.replacedCount,
    this.updatedContent,
  });

  final List<StyleRecord> records;
  final int replacedCount;
  final String? updatedContent;
}

class _IntermediateScanResult {
  const _IntermediateScanResult({
    required this.records,
    required this.replacedCount,
    this.updatedContent,
  });

  final List<StyleRecord> records;
  final int replacedCount;
  final String? updatedContent;
}

class FileReport {
  const FileReport({
    required this.path,
    required this.records,
    required this.replacedCount,
  });

  final String path;
  final List<StyleRecord> records;
  final int replacedCount;

  String get summaryLine {
    final int heightCount = records
        .where((StyleRecord record) => record.hasHeight)
        .length;
    final int familyCount = records
        .where((StyleRecord record) => record.hasFontFamily)
        .length;
    return '$path | count=${records.length}, height=$heightCount, '
        'fontFamily=$familyCount, replaced=$replacedCount';
  }
}

class StyleRecord {
  const StyleRecord({
    required this.line,
    required this.hasHeight,
    required this.hasFontFamily,
    required this.suggestedFactory,
    required this.sourceType,
    required this.status,
  });

  final int line;
  final bool hasHeight;
  final bool hasFontFamily;
  final String? suggestedFactory;
  final String sourceType;
  final String status;
}

class StyleAnalysis {
  const StyleAnalysis({
    required this.properties,
    this.factory,
    this.replacement,
  });

  final Map<String, String> properties;
  final String? factory;
  final String? replacement;
}

class _StyleOccurrence {
  const _StyleOccurrence({
    required this.fullStart,
    required this.start,
    required this.end,
  });

  final int fullStart;
  final int start;
  final int end;
}

class _ThemeStyleOccurrence {
  const _ThemeStyleOccurrence({
    required this.fullStart,
    required this.copyWithStart,
    required this.end,
    required this.themeSlot,
  });

  final int fullStart;
  final int copyWithStart;
  final int end;
  final String themeSlot;
}

class _ThemeTextSpec {
  const _ThemeTextSpec({required this.fontSize, required this.fontWeight});

  final double fontSize;
  final int fontWeight;

  String get fontSizeLabel {
    final int maybeInt = fontSize.toInt();
    return fontSize == maybeInt ? maybeInt.toString() : fontSize.toString();
  }

  String get fontWeightLabel => 'FontWeight.w$fontWeight';
}

class TestStyleFamily {
  const TestStyleFamily._();

  static const String sfUiText = 'sf_ui_text';
  static const String pingFang = 'ping_fang';
  static const String miSansLatin = 'mi_sans_latin';
  static const String alibabaPuHuiTi = 'alibaba_puhuiti';
}
