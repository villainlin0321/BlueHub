import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
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
  static const _regionOptions = <LoginRegionOption>[
    LoginRegionOption(label: '中国大陆', code: '+86'),
    LoginRegionOption(label: '中国香港', code: '+852'),
    LoginRegionOption(label: '中国澳门', code: '+853'),
    LoginRegionOption(label: '新加坡', code: '+65'),
  ];

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
  final _emailController = TextEditingController(text: 'zhaolei@example.com');
  final _codeController = TextEditingController(text: '1234');

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _showRegionPicker() async {
    final state = ref.read(loginFormControllerProvider);
    final selectedRegion = _regionOptions
        .where((option) => option.code == state.regionCode)
        .first;
    final region = await showModalBottomSheet<LoginRegionOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RegionPickerSheet(options: _regionOptions, selected: selectedRegion),
    );

    if (region != null) {
      ref.read(loginFormControllerProvider.notifier).setRegionCode(region.code);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(loginFormControllerProvider);
    final authSession = ref.watch(authSessionProvider);

    ref.listen(loginFormControllerProvider, (previous, next) {
      if (previous?.feedbackId == next.feedbackId ||
          next.feedbackMessage == null) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(next.feedbackMessage!)));
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
                  onRegionTap: _showRegionPicker,
                  onLanguageChanged: (isChineseSelected) {
                    ref
                        .read(loginFormControllerProvider.notifier)
                        .setLanguageSelected(isChineseSelected);
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
