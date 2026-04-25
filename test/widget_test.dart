import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluehub_app/main.dart';

/// Widget 测试入口
void main() {
  testWidgets('首页到设置页跳转', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('进入设置页'), findsOneWidget);

    await tester.tap(find.text('进入设置页'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('返回'), findsOneWidget);

    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();

    expect(find.text('进入设置页'), findsOneWidget);
  });
}
