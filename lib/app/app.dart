import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/localization/app_locales.dart';
import '../shared/logging/app_lifecycle_logger.dart';
import '../shared/network/providers.dart';
import '../shared/widgets/app_toast.dart';
import 'router/app_router.dart';

final appTitleProvider = Provider<String>((ref) => '应用.标题'.tr());

class App extends ConsumerWidget {
  const App({super.key});

  @override
  /// 构建应用根节点，并把 easy_localization 提供的多语言配置注入到路由应用。
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final title = ref.watch(appTitleProvider);
    AppToast.configure();

    return _AppLocaleInitialSync(
      child: AppLifecycleLogger(
        child: MaterialApp.router(
          key: const Key('app-root'),
          title: title,
          debugShowCheckedModeBanner: false,
          locale: context.locale,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF186CFF),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            useMaterial3: true,
          ),
          builder: (BuildContext context, Widget? child) {
            final TransitionBuilder easyLoadingBuilder = EasyLoading.init();
            return easyLoadingBuilder(
              context,
              child ?? const SizedBox.shrink(),
            );
          },
          routerConfig: router,
        ),
      ),
    );
  }
}

class _AppLocaleInitialSync extends StatefulWidget {
  const _AppLocaleInitialSync({required this.child});

  final Widget child;

  @override
  State<_AppLocaleInitialSync> createState() => _AppLocaleInitialSyncState();
}

class _AppLocaleInitialSyncState extends State<_AppLocaleInitialSync> {
  bool _didSync = false;

  @override
  /// 首次进入应用时，根据当前 Locale 同步一次全局语言码缓存。
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didSync) {
      return;
    }
    _didSync = true;

    final locale = context.locale;
    ProviderScope.containerOf(context, listen: false)
        .read(appLanguageStoreProvider)
        .syncLanguageCode(AppLocales.toLanguageCode(locale));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
