import 'package:europepass/features/me/presentation/job_seeker_real_name_verification_page.dart';
import 'package:europepass/features/me/presentation/role_pages/job_seeker_me_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('未实名入口会展示引导文案并响应点击', (WidgetTester tester) async {
    var didTap = false;

    await tester.pumpWidget(
      _buildLocalizedApp(
        child: Scaffold(
          body: JobSeekerRealNameEntry(
            isVerified: false,
            onTap: () => didTap = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的.点击去实名认证'), findsOneWidget);

    await tester.tap(find.text('我的.点击去实名认证'));
    await tester.pumpAndSettle();

    expect(didTap, isTrue);
  });

  testWidgets('已实名入口会展示完成实名认证文案', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildLocalizedApp(
        child: const Scaffold(
          body: JobSeekerRealNameEntry(
            isVerified: true,
            onTap: _noop,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的.已完成实名认证'), findsOneWidget);
    expect(find.text('我的.点击去实名认证'), findsNothing);
  });

  testWidgets('实名认证占位页会展示标题', (WidgetTester tester) async {
    await tester.pumpWidget(
      _buildLocalizedApp(
        child: const JobSeekerRealNameVerificationPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('我的.实名认证'), findsWidgets);
  });
}

/// 构建最小测试宿主，专注验证组件分支和点击行为，不引入额外路由或本地化噪音。
Widget _buildLocalizedApp({required Widget child}) {
  return MaterialApp(
    home: child,
  );
}

/// 提供无副作用点击回调，方便只验证展示分支的组件测试复用。
void _noop() {}
