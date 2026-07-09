import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:europepass/features/service_detail/presentation/service_detail_bottom_sheets.dart';
import 'package:europepass/features/service_detail/presentation/service_detail_package_tab.dart';
import 'package:europepass/shared/localization/app_locales.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('申请弹窗支付按钮位于内容区并随表单一起滚动', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.english,
        startLocale: AppLocales.chinese,
        saveLocale: false,
        useOnlyLangCode: true,
        child: const ProviderScope(
          child: MaterialApp(home: _ApplyBottomSheetTestHome()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('open_apply_bottom_sheet')),
    );
    await tester.pumpAndSettle();

    final Finder scrollView = find.byType(SingleChildScrollView);
    final Finder actionButtonsInScroll = find.descendant(
      of: scrollView,
      matching: find.byType(FilledButton),
    );
    final Finder inputsInScroll = find.descendant(
      of: scrollView,
      matching: find.byType(TextField),
    );
    final Finder allButtons = find.byType(FilledButton);
    expect(inputsInScroll, findsNWidgets(2));
    expect(actionButtonsInScroll, findsOneWidget);
    expect(allButtons, findsNWidgets(2));

    final Finder firstInput = find.byType(TextField).first;
    await tester.tap(firstInput);
    await tester.pumpAndSettle();

    expect(inputsInScroll, findsNWidgets(2));
    expect(actionButtonsInScroll, findsOneWidget);
    expect(allButtons, findsNWidgets(2));
  });

  testWidgets('Android 主动收起键盘后输入框失焦并恢复底部支付按钮', (WidgetTester tester) async {
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: AppLocales.supported,
        path: 'assets/translations',
        fallbackLocale: AppLocales.english,
        startLocale: AppLocales.chinese,
        saveLocale: false,
        useOnlyLangCode: true,
        child: const ProviderScope(
          child: MaterialApp(home: _ApplyBottomSheetTestHome()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('open_apply_bottom_sheet')),
    );
    await tester.pumpAndSettle();

    final Finder firstInput = find.byType(TextField).first;
    await tester.tap(firstInput);
    await tester.pump();

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pump();

    final EditableText focusedEditableText = tester.widget<EditableText>(
      find.descendant(of: firstInput, matching: find.byType(EditableText)),
    );
    expect(focusedEditableText.focusNode.hasFocus, isTrue);
    expect(find.byType(FilledButton), findsNWidgets(2));

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pump();
    await tester.pump();

    final EditableText unfocusedEditableText = tester.widget<EditableText>(
      find.descendant(of: firstInput, matching: find.byType(EditableText)),
    );
    expect(unfocusedEditableText.focusNode.hasFocus, isFalse);
    expect(find.byType(FilledButton), findsNWidgets(2));
  });
}

class _ApplyBottomSheetTestHome extends StatefulWidget {
  const _ApplyBottomSheetTestHome();

  @override
  State<_ApplyBottomSheetTestHome> createState() =>
      _ApplyBottomSheetTestHomeState();
}

class _ApplyBottomSheetTestHomeState extends State<_ApplyBottomSheetTestHome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('open_apply_bottom_sheet'),
          onPressed: () {
            ServiceDetailApplyBottomSheet.show(
              context: context,
              serviceTitle: '测试服务',
              package: const ServicePackageData(
                packageId: 1,
                tierId: 2,
                title: '标准套餐',
                amount: 199,
                currency: 'CNY',
                price: '¥199',
                description: '测试描述',
                tags: <String>[],
              ),
            );
          },
          child: const Text('Open'),
        ),
      ),
    );
  }
}
