import 'package:europepass/shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('点击空白区域后输入框会失焦', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TapBlankToDismissKeyboard(
            child: Column(
              children: <Widget>[
                TextField(key: const Key('field'), focusNode: focusNode),
                const Expanded(child: SizedBox(key: Key('blank'))),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('blank')), warnIfMissed: false);
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('点击可点击子组件后也会收起当前焦点', (WidgetTester tester) async {
    final FocusNode focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TapBlankToDismissKeyboard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(key: const Key('field'), focusNode: focusNode),
                TextButton(
                  key: const Key('action'),
                  onPressed: () {},
                  child: const Text('action'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('field')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.byKey(const Key('action')));
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
  });
}
