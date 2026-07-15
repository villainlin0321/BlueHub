import 'package:europepass/shared/widgets/unsaved_changes_exit_guard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 验证未保存改动退出确认 helper 的放行与拦截行为。
void main() {
  testWidgets('无改动时直接允许离开', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    final bool canLeave = await confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: false,
    );

    expect(canLeave, isTrue);
    expect(find.text('现在退出，内容将不会保存'), findsNothing);
  });

  testWidgets('有改动时弹出确认框并支持取消', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    final Future<bool> result = confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: true,
    );

    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
  });

  testWidgets('有改动时点击确定后允许离开', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SizedBox.shrink()),
      ),
    );

    final BuildContext context = tester.element(find.byType(Scaffold));
    final Future<bool> result = confirmDiscardChangesIfNeeded(
      context: context,
      hasUnsavedChanges: true,
    );

    await tester.pumpAndSettle();

    expect(find.text('现在退出，内容将不会保存'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);

    // 点击确认后应关闭弹窗并允许页面继续返回。
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });
}
