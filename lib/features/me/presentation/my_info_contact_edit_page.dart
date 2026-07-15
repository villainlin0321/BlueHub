import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/network/api_exception.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../auth/application/auth_session_provider.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_providers.dart';
import '../data/user_models.dart';
import '../data/user_providers.dart';

import 'package:europepass/shared/ui/test_style.dart';

enum MyInfoContactEditMode { phone, email }

class MyInfoContactEditPageArgs {
  const MyInfoContactEditPageArgs({required this.mode});

  const MyInfoContactEditPageArgs.email() : mode = MyInfoContactEditMode.email;

  const MyInfoContactEditPageArgs.phone() : mode = MyInfoContactEditMode.phone;

  final MyInfoContactEditMode mode;
}

class MyInfoContactEditPage extends ConsumerStatefulWidget {
  const MyInfoContactEditPage({
    super.key,
    this.args = const MyInfoContactEditPageArgs.email(),
  });

  final MyInfoContactEditPageArgs args;

  @override
  ConsumerState<MyInfoContactEditPage> createState() =>
      _MyInfoContactEditPageState();
}

class _MyInfoContactEditPageState extends ConsumerState<MyInfoContactEditPage> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final TextEditingController _accountController;
  late final TextEditingController _codeController;

  Timer? _countdownTimer;
  int _resendCountdownSeconds = 0;
  bool _isSendingCode = false;
  bool _isSubmitting = false;

  bool get _isEmailMode => widget.args.mode == MyInfoContactEditMode.email;

  bool get _canSave =>
      _accountController.text.trim().isNotEmpty &&
      _codeController.text.trim().isNotEmpty &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authSessionProvider).user;
    _accountController = TextEditingController(
      text: _isEmailMode
          ? (user?.email.trim() ?? '')
          : (user?.phone.trim() ?? ''),
    );
    _codeController = TextEditingController();
    _accountController.addListener(_handleFieldChanged);
    _codeController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _accountController.removeListener(_handleFieldChanged);
    _codeController.removeListener(_handleFieldChanged);
    _accountController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _handleSendCode() async {
    if (_isSendingCode || _resendCountdownSeconds > 0) {
      return;
    }

    final String? validationError = _validateAccount();
    if (validationError != null) {
      await AppToast.show(validationError);
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      if (_isEmailMode) {
        await authService.sendEmailCode(
          request: SendEmailBO(
            email: _accountController.text.trim(),
            scene: 'bind',
          ),
        );
        await AppToast.show('认证.已发送邮箱验证码'.tr());
      } else {
        final String countryCode =
            ref.read(authSessionProvider).user?.countryCode.trim().isNotEmpty ==
                true
            ? ref.read(authSessionProvider).user!.countryCode.trim()
            : '+86';
        await authService.sendSms(
          request: SendSmsBO(
            phone: _accountController.text.trim(),
            countryCode: countryCode,
            scene: 'bind',
          ),
        );
        await AppToast.show('认证.已发送短信验证码'.tr());
      }
      _startCountdown();
    } catch (error) {
      final String message = error is ApiException
          ? error.message
          : '认证.验证码发送失败'.tr();
      await AppToast.show(message);
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    final String? validationError = _validateAccount();
    if (validationError != null) {
      await AppToast.show(validationError);
      return;
    }
    if (_codeController.text.trim().isEmpty) {
      await AppToast.show(
        _isEmailMode ? '认证.请输入邮箱验证码校验'.tr() : '认证.请输入短信验证码'.tr(),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      final String value = _accountController.text.trim();
      final String code = _codeController.text.trim();
      final authSession = ref.read(authSessionProvider);
      final userService = ref.read(userServiceProvider);
      if (_isEmailMode) {
        await userService.bindEmail(
          request: BindEmailBO(email: value, code: code),
        );
      } else {
        final String countryCode =
            ref.read(authSessionProvider).user?.countryCode.trim().isNotEmpty ==
                true
            ? ref.read(authSessionProvider).user!.countryCode.trim()
            : '+86';
        await userService.bindPhone(
          request: BindPhoneBO(
            phone: value,
            countryCode: countryCode,
            code: code,
          ),
        );
      }
      await ref
          .read(authSessionProvider.notifier)
          .refreshCurrentUser(
            fallbackUser: authSession.user,
            preferredNeedSelectRole: authSession.needSelectRole,
          );
      await AppToast.show(_isEmailMode ? '我的.邮箱已更新'.tr() : '我的.手机号已更新'.tr());
      if (mounted && context.canPop()) {
        context.pop();
      }
    } catch (error) {
      final String message = error is ApiException
          ? error.message
          : '我的.保存失败'.tr();
      await AppToast.show(message);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String? _validateAccount() {
    final String value = _accountController.text.trim();
    if (_isEmailMode) {
      if (value.isEmpty) {
        return '认证.请输入邮箱校验'.tr();
      }
      if (!_emailPattern.hasMatch(value)) {
        return '认证.邮箱格式错误'.tr();
      }
      return null;
    }

    if (value.isEmpty) {
      return '认证.请输入手机号校验'.tr();
    }
    if (!RegExp(r'^\d{6,20}$').hasMatch(value)) {
      return '通用.请输入正确的手机号'.tr();
    }
    return null;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _resendCountdownSeconds = 60;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _resendCountdownSeconds = 0;
        });
        return;
      }
      setState(() {
        _resendCountdownSeconds -= 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color buttonColor = _canSave
        ? const Color(0xFF096DD9)
        : const Color(0xFF9FC4EF);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _ContactEditHeader(title: _pageTitle, onBackTap: context.pop),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Text(
                _pageTitle,
                style: TestStyle.pingFangSemibold(
                  fontSize: 26,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
            const SizedBox(height: 72),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _UnderlinedInput(
                fieldKey: const Key('my-info-contact-account-input'),
                controller: _accountController,
                hintText: _accountHintText,
                keyboardType: _isEmailMode
                    ? TextInputType.emailAddress
                    : TextInputType.phone,
                inputFormatters: _isEmailMode
                    ? const <TextInputFormatter>[]
                    : <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(20),
                      ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _VerificationCodeRow(
                controller: _codeController,
                sendButtonText: _resendCountdownSeconds > 0
                    ? '${_resendCountdownSeconds}s'
                    : '认证.获取验证码'.tr(),
                isBusy: _isSendingCode,
                onSendTap: _handleSendCode,
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                height: 44,
                child: FilledButton(
                  key: const Key('my-info-contact-save-button'),
                  onPressed: _canSave ? _handleSave : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: buttonColor,
                    disabledBackgroundColor: buttonColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          '我的.保存'.tr(),
                          style: TestStyle.pingFangMedium(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _pageTitle => _isEmailMode ? '我的.绑定邮箱号'.tr() : '我的.绑定手机号'.tr();

  String get _accountHintText =>
      _isEmailMode ? '认证.请输入邮箱'.tr() : '通用.请输入手机号'.tr();
}

class _ContactEditHeader extends StatelessWidget {
  const _ContactEditHeader({required this.title, required this.onBackTap});

  final String title;
  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
            ),
          ),
          Text(
            title,
            style: TestStyle.pingFangMedium(
              fontSize: 17,
              color: const Color(0xFF262626),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderlinedInput extends StatelessWidget {
  const _UnderlinedInput({
    required this.fieldKey,
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.inputFormatters,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final List<TextInputFormatter> inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          key: fieldKey,
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          cursorColor: AppColors.brand,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: hintText,
            hintStyle: TestStyle.pingFangRegular(
              fontSize: 16,
              color: const Color(0xFFBFBFBF),
            ),
          ),
          style: TestStyle.pingFangRegular(
            fontSize: 16,
            color: const Color(0xFF262626),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}

class _VerificationCodeRow extends StatelessWidget {
  const _VerificationCodeRow({
    required this.controller,
    required this.sendButtonText,
    required this.isBusy,
    required this.onSendTap,
  });

  final TextEditingController controller;
  final String sendButtonText;
  final bool isBusy;
  final VoidCallback onSendTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const Key('my-info-contact-code-input'),
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                cursorColor: AppColors.brand,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '认证.请输入验证码'.tr(),
                  hintStyle: TestStyle.pingFangRegular(
                    fontSize: 16,
                    color: const Color(0xFFBFBFBF),
                  ),
                ),
                style: TestStyle.pingFangRegular(
                  fontSize: 16,
                  color: const Color(0xFF262626),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              key: const Key('my-info-contact-send-code-button'),
              onTap: isBusy ? null : onSendTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  sendButtonText,
                  style: TestStyle.pingFangRegular(
                    fontSize: 14,
                    color: const Color(0xFF186CFF),
                  ),
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}
