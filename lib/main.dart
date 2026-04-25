import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// 应用入口
void main() {
  runApp(const ProviderScope(child: App()));
}

/// 提供应用标题（示例：后续可替换为配置/本地化/远端下发）
final appTitleProvider = Provider<String>((ref) => 'BlueHub');

/// 路由配置（集中管理所有页面的入口与跳转规则）
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});

/// 应用根组件（Riverpod + go_router）
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final title = ref.watch(appTitleProvider);

    return MaterialApp.router(
      title: title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routerConfig: router,
    );
  }
}

/// 首页
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = ref.watch(appTitleProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('空项目骨架已就绪（Riverpod + go_router）'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // 关键跳转：由 go_router 统一管理路由
                context.push('/settings');
              },
              child: const Text('进入设置页'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 设置页
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // 返回上一页
            context.pop();
          },
          child: const Text('返回'),
        ),
      ),
    );
  }
}
