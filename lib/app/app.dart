import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/localization/app_locales.dart';
import 'router/app_router.dart';

final appTitleProvider = Provider<String>((ref) => '应用.标题'.tr());

class App extends ConsumerWidget {
  const App({super.key});

  @override
  /// 构建应用根节点，并把 easy_localization 提供的多语言配置注入到路由应用。
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final title = ref.watch(appTitleProvider);

    return MaterialApp.router(
      title: title,
      locale: context.locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: context.localizationDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF186CFF)),
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
