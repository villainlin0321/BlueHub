import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/localization/app_locales.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../application/auth_session_provider.dart';
import '../application/login/login_form_controller.dart';
import 'widgets/login_phone_view.dart';

class LoginPhonePage extends ConsumerStatefulWidget {
  const LoginPhonePage({super.key});

  @override
  ConsumerState<LoginPhonePage> createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends ConsumerState<LoginPhonePage> {
  static const String _workerTestEmail = 'zhangwei@example.com';
  static const String _employerTestEmail = 'berlin.food@example.de';
  static const String _serviceProviderTestEmail = 'oulu@example.com';
  /// 统一测试账号验证码，便于本地直登和联调时保持一致。
  static const String _testCode = '123456';

  final _phoneController = TextEditingController();

  // worker
  // zhangwei@example.com
  // zhaolei@example.com
  // employer
  // berlin.food@example.de
  // munich.build@example.de
  // visa _provider
  // oulu@example.com
  // zhongde@example.com
  // final _emailController = TextEditingController();
  final _emailController = TextEditingController(text: _workerTestEmail);
  final _codeController = TextEditingController(text: _testCode);

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 按当前语言构建地区列表，让地区选择弹层能随语言实时切换。
  List<LoginRegionOption> _buildRegionOptions(BuildContext context) {
    return <LoginRegionOption>[
      LoginRegionOption(label: tr('认证.中国大陆'), code: '+86'),
      LoginRegionOption(label: tr('认证.中国香港'), code: '+852'),
      LoginRegionOption(label: tr('认证.中国澳门'), code: '+853'),
      LoginRegionOption(label: tr('认证.新加坡'), code: '+65'),
    ];
  }

  /// 展示地区选择器，并把选中的区号同步回登录表单状态。
  Future<void> _showRegionPicker() async {
    final state = ref.read(loginFormControllerProvider);
    final regionOptions = _buildRegionOptions(context);
    final selectedRegion = regionOptions
        .where((option) => option.code == state.regionCode)
        .first;
    final region = await showModalBottomSheet<LoginRegionOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RegionPickerSheet(options: regionOptions, selected: selectedRegion),
    );

    if (region != null) {
      ref.read(loginFormControllerProvider.notifier).setRegionCode(region.code);
    }
  }

  /// 处理常规登录，登录成功后根据接口状态跳转首页或角色选择页。
  Future<void> _handleLogin() async {
    final login = await ref
        .read(loginFormControllerProvider.notifier)
        .submitLogin();
    if (!mounted || login == null) {
      return;
    }

    if (login.needSelectRole) {
      context.goNamed(RoutePaths.selectRoleName);
      return;
    }

    context.goNamed(RoutePaths.homeName);
  }

  /// 按测试角色填充邮箱与验证码，并直接发起邮箱验证码登录。
  Future<void> _handleDirectEmailLogin(String email) async {
    _emailController.text = email;
    _codeController.text = _testCode;

    final notifier = ref.read(loginFormControllerProvider.notifier);
    notifier.setLoginMode(false);
    notifier.updateEmail(email);
    notifier.updateCode(_testCode);

    final login = await ref
        .read(loginFormControllerProvider.notifier)
        .submitEmailLoginWithoutValidation(email: email, code: _testCode);
    if (!mounted || login == null) {
      return;
    }

    if (login.needSelectRole) {
      context.goNamed(RoutePaths.selectRoleName);
      return;
    }

    context.goNamed(RoutePaths.homeName);
  }

  @override
  /// 构建登录页，并把当前全局语言状态透传给语言切换组件。
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormControllerProvider);
    final authSession = ref.watch(authSessionProvider);
    final isChineseSelected = context.isChineseLocale;

    ref.listen(loginFormControllerProvider, (previous, next) {
      if (previous?.feedbackId == next.feedbackId ||
          next.feedbackMessage == null) {
        return;
      }

      AppToast.show(next.feedbackMessage!);
      ref.read(loginFormControllerProvider.notifier).clearFeedback();
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: TapBlankToDismissKeyboard(
        child: SafeArea(
          child: authSession.isHydrating && !authSession.isAuthenticated
              ? const Center(child: CircularProgressIndicator())
              : LoginPhoneView(
                  state: formState,
                  phoneController: _phoneController,
                  emailController: _emailController,
                  codeController: _codeController,
                  isChineseSelected: isChineseSelected,
                  onRegionTap: _showRegionPicker,
                  onLanguageChanged: (isChineseSelected) async {
                    await context.switchAppLocale(isChineseSelected);
                  },
                  onLoginModeChanged: (isPhoneLogin) {
                    ref
                        .read(loginFormControllerProvider.notifier)
                        .setLoginMode(isPhoneLogin);
                  },
                  onPhoneChanged: ref
                      .read(loginFormControllerProvider.notifier)
                      .updatePhone,
                  onEmailChanged: ref
                      .read(loginFormControllerProvider.notifier)
                      .updateEmail,
                  onCodeChanged: ref
                      .read(loginFormControllerProvider.notifier)
                      .updateCode,
                  onSendCode: () {
                    ref.read(loginFormControllerProvider.notifier).sendCode();
                  },
                  onLogin: _handleLogin,
                  onTestWorkerLogin: () {
                    _handleDirectEmailLogin(_workerTestEmail);
                  },
                  onTestServiceProviderLogin: () {
                    _handleDirectEmailLogin(_serviceProviderTestEmail);
                  },
                  onTestEmployerLogin: () {
                    _handleDirectEmailLogin(_employerTestEmail);
                  },
                  onAgreementChanged: (agreed) {
                    ref
                        .read(loginFormControllerProvider.notifier)
                        .setAgreement(agreed);
                  },
                ),
        ),
      ),
    );
  }
}
