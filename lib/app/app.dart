import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/app_icon/app_icon_switcher.dart';
import '../shared/localization/app_locales.dart';
import '../shared/logging/app_lifecycle_logger.dart';
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

    return _AppIconInitialSync(
      child: AppLifecycleLogger(
        child: MaterialApp.router(
          title: title,
          debugShowCheckedModeBanner: false,
          locale: context.locale,
          supportedLocales: AppLocales.supported,
          localizationsDelegates: context.localizationDelegates,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF186CFF)),
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            useMaterial3: true,
          ),
          builder: (BuildContext context, Widget? child) {
            final TransitionBuilder easyLoadingBuilder = EasyLoading.init();
            return easyLoadingBuilder(context, child ?? const SizedBox.shrink());
          },
          routerConfig: router,
        ),
      ),
    );
  }
}

class _AppIconInitialSync extends StatefulWidget {
  const _AppIconInitialSync({required this.child});

  final Widget child;

  @override
  State<_AppIconInitialSync> createState() => _AppIconInitialSyncState();
}

class _AppIconInitialSyncState extends State<_AppIconInitialSync> {
  bool _didSync = false;

  @override
  /// 首次进入应用时，根据当前 Locale 同步一次系统桌面图标（后续语言切换由 switchAppLocale 主动触发）。
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didSync) {
      return;
    }
    _didSync = true;

    final locale = context.locale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppIconSwitcher.syncByLocale(locale);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
