import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:europepass/features/config/data/config_models.dart';
import 'package:europepass/features/jobs/presentation/widgets/post_job_page_view.dart';
import 'package:europepass/shared/localization/app_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('拖动岗位发布页后输入框会失焦', (WidgetTester tester) async {
    await tester.pumpWidget(_buildPostJobPageViewTestHost());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(EditableText).first);
    await tester.pump();
    expect(_findEditableText(tester).focusNode.hasFocus, isTrue);

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -160));
    await tester.pump();

    expect(_findEditableText(tester).focusNode.hasFocus, isFalse);
  });

  testWidgets('岗位发布页滚动容器启用拖动收起键盘', (WidgetTester tester) async {
    await tester.pumpWidget(_buildPostJobPageViewTestHost());
    await tester.pumpAndSettle();

    final SingleChildScrollView scrollView = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );

    expect(
      scrollView.keyboardDismissBehavior,
      ScrollViewKeyboardDismissBehavior.onDrag,
    );
  });
}

/// 构建带本地化能力的岗位发布页测试宿主，确保 `.tr()` 在测试环境下可正常解析。
Widget _buildPostJobPageViewTestHost() {
  return EasyLocalization(
    supportedLocales: AppLocales.supported,
    path: 'assets/translations',
    assetLoader: const _TestJsonFileAssetLoader(),
    fallbackLocale: AppLocales.chinese,
    startLocale: AppLocales.chinese,
    saveLocale: false,
    child: const _PostJobPageViewTestApp(),
  );
}

/// 直接从仓库读取翻译资源，避免 Widget 测试里出现空白文案或缺失委托。
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

/// 提供岗位发布页最小可运行宿主，只保留失焦验证所需的控制器和空回调。
class _PostJobPageViewTestApp extends StatefulWidget {
  const _PostJobPageViewTestApp();

  @override
  State<_PostJobPageViewTestApp> createState() => _PostJobPageViewTestAppState();
}

class _PostJobPageViewTestAppState extends State<_PostJobPageViewTestApp> {
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _headcountController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _packageNameController.dispose();
    _countryController.dispose();
    _headcountController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _customTagController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: PostJobPageView(
        title: '岗位发布',
        publishButtonLabel: '发布',
        packageNameController: _packageNameController,
        countryController: _countryController,
        headcountController: _headcountController,
        minSalaryController: _minSalaryController,
        maxSalaryController: _maxSalaryController,
        customTagController: _customTagController,
        descriptionController: _descriptionController,
        jobTypes: const <String>['full_time', 'part_time'],
        salaryUnits: const <String>['month', 'week'],
        selectedJobType: 'full_time',
        selectedSalaryUnit: 'month',
        selectedSalaryCurrencyLabel: 'EUR',
        requirementTags: const <TagItemVO>[],
        selectedRequirementTagCodes: const <String>{},
        customTags: const <String>[],
        isLoadingRequirementTags: false,
        requirementTagsError: null,
        isPublishing: false,
        onBack: () {},
        onSaveDraft: () {},
        onPublish: () {},
        onRetryLoadRequirementTags: () {},
        onJobTypeChanged: (_) {},
        onSalaryUnitChanged: (_) {},
        onSalaryCurrencyTap: () {},
        onRequirementTagTap: (_) {},
        onRemoveCustomTag: (_) {},
        onCustomTagSubmitted: (_) {},
        tagLabelBuilder: (TagItemVO item) => item.tagNameZh,
      ),
    );
  }
}

/// 读取当前页面首个真实输入框，便于断言拖动后是否已释放焦点。
EditableText _findEditableText(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText).first);
}
