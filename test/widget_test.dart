import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluehub_app/app/app.dart';

/// Widget 测试入口
void main() {
  testWidgets('基础渲染：进入首页', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // 关键点：只做冒烟测试，确保路由与首页 UI 能正常渲染。
    expect(find.text('早上好，程先生'), findsOneWidget);
    expect(find.text('首页'), findsWidgets);
  });
}
