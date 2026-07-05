import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/me/presentation/self_evaluation_page.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:europepass/shared/ui/test_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('拖动自我评价页后输入框会失焦', (WidgetTester tester) async {
    await tester.pumpWidget(_buildSelfEvaluationTestHost());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(AppTestKeys.fieldSelfEvaluationInput));
    await tester.pump();
    expect(_findEditableText(tester).focusNode.hasFocus, isTrue);

    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -120),
    );
    await tester.pump();

    expect(_findEditableText(tester).focusNode.hasFocus, isFalse);
  });
}

/// 构建带本地化能力的自我评价页测试宿主，避免 `tr()` 在测试环境下失效。
Widget _buildSelfEvaluationTestHost() {
  return EasyLocalization(
    supportedLocales: AppLocales.supported,
    path: 'assets/translations',
    assetLoader: const _TestJsonFileAssetLoader(),
    fallbackLocale: AppLocales.chinese,
    startLocale: AppLocales.chinese,
    saveLocale: false,
    child: const _SelfEvaluationTestApp(),
  );
}

/// 直接从仓库读取翻译资源，保证 Widget 测试可拿到真实文案。
class _TestJsonFileAssetLoader extends AssetLoader {
  const _TestJsonFileAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final File file = File(
      '${Directory.current.path}/$path/${locale.languageCode}.json',
    );
    final String content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  }
}

/// 提供最小可运行的页面宿主，承接本地化与 Material 依赖。
class _SelfEvaluationTestApp extends StatelessWidget {
  const _SelfEvaluationTestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: const SelfEvaluationPage(),
    );
  }
}

/// 读取页面中真实承载输入焦点的 `EditableText`，用于断言失焦结果。
EditableText _findEditableText(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText));
}
