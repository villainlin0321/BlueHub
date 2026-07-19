import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_error_feedback.dart';
import '../../data/auth_models.dart';
import '../../data/auth_providers.dart';
import '../../data/login_account_store.dart';
import '../auth_session_provider.dart';
import 'login_form_state.dart';

final loginFormControllerProvider =
    NotifierProvider.autoDispose<LoginFormController, LoginFormState>(
      LoginFormController.new,
    );

class LoginFormController extends Notifier<LoginFormState> {
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static const int _sendCodeCountdownSeconds = 60;

  Timer? _sendCodeCountdownTimer;

  @override
  LoginFormState build() {
    ref.onDispose(() {
      _sendCodeCountdownTimer?.cancel();
      _sendCodeCountdownTimer = null;
    });
    return const LoginFormState();
  }

  void setLoginMode(bool isPhoneLogin) {
    state = state.copyWith(isPhoneLogin: isPhoneLogin);
  }

  void setAgreement(bool agreed) {
    state = state.copyWith(agreed: agreed);
  }

  void setRegionCode(String regionCode) {
    state = state.copyWith(regionCode: regionCode);
  }

  void updatePhone(String phone) {
    state = state.copyWith(phone: phone);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void updateCode(String code) {
    state = state.copyWith(code: code);
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }

  /// 发送验证码，并返回本次发送是否成功，便于页面层串联后续登录动作。
  Future<bool> sendCode() async {
    if (state.isSendingCode || state.resendCountdownSeconds > 0) {
      return false;
    }

    final validationError = _validateBeforeSendingCode();
    if (validationError != null) {
      _emitFeedback(validationError, isError: true);
      return false;
    }

    state = state.copyWith(isSendingCode: true);

    try {
      final authService = ref.read(authServiceProvider);
      if (state.isPhoneLogin) {
        await authService.sendSms(
          request: SendSmsBO(
            phone: state.phone.trim(),
            countryCode: state.regionCode,
            scene: 'login',
          ),
        );
        _startSendCodeCountdown();
        _emitFeedback(tr('认证.已发送短信验证码'));
      } else {
        await authService.sendEmailCode(
          request: SendEmailBO(email: state.email.trim(), scene: 'login'),
        );
        _startSendCodeCountdown();
        _emitFeedback(tr('认证.已发送邮箱验证码'));
      }
      return true;
    } catch (error) {
      _emitFeedback(
        ApiErrorFeedback.resolveMessage(error, fallback: tr('认证.验证码发送失败')),
        isError: true,
      );
      return false;
    } finally {
      state = state.copyWith(isSendingCode: false);
    }
  }

  Future<LoginVO?> submitLogin() async {
    final validationError = _validateBeforeLogin();
    if (validationError != null) {
      _emitFeedback(validationError, isError: true);
      return null;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final authService = ref.read(authServiceProvider);
      final login = state.isPhoneLogin
          ? await authService.phoneLogin(
              request: PhoneLoginBO(
                phone: state.phone.trim(),
                countryCode: state.regionCode,
                code: state.code.trim(),
              ),
            )
          : await authService.emailLogin(
              request: EmailLoginBO(
                email: state.email.trim(),
                password: '',
                code: state.code.trim(),
              ),
            );
      await ref.read(authSessionProvider.notifier).handleLoginResult(login);
      await ref
          .read(loginAccountStoreProvider)
          .save(
            mode: state.isPhoneLogin
                ? LoginAccountMode.phone
                : LoginAccountMode.email,
            account: state.currentAccount,
          );
      return login;
    } catch (error) {
      _emitFeedback(
        ApiErrorFeedback.resolveMessage(error, fallback: tr('认证.登录失败')),
        isError: true,
      );
      return null;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  void _startSendCodeCountdown() {
    _sendCodeCountdownTimer?.cancel();
    state = state.copyWith(resendCountdownSeconds: _sendCodeCountdownSeconds);
    _sendCodeCountdownTimer = Timer.periodic(const Duration(seconds: 1), (
      timer,
    ) {
      final nextSeconds = state.resendCountdownSeconds - 1;
      if (nextSeconds <= 0) {
        timer.cancel();
        _sendCodeCountdownTimer = null;
        state = state.copyWith(resendCountdownSeconds: 0);
        return;
      }

      state = state.copyWith(resendCountdownSeconds: nextSeconds);
    });
  }

  String? _validateBeforeSendingCode() {
    if (!state.agreed) {
      return tr('认证.请先同意协议');
    }

    if (state.isPhoneLogin) {
      if (state.phone.trim().isEmpty) {
        return tr('认证.请输入手机号校验');
      }
      return null;
    }

    if (state.email.trim().isEmpty) {
      return tr('认证.请输入邮箱校验');
    }
    if (!_emailPattern.hasMatch(state.email.trim())) {
      return tr('认证.邮箱格式错误');
    }
    return null;
  }

  String? _validateBeforeLogin() {
    final sendCodeError = _validateBeforeSendingCode();
    if (sendCodeError != null) {
      return sendCodeError;
    }
    if (state.code.trim().isEmpty) {
      return state.isPhoneLogin ? tr('认证.请输入短信验证码') : tr('认证.请输入邮箱验证码校验');
    }
    return null;
  }

  void _emitFeedback(String message, {bool isError = false}) {
    state = state.copyWith(
      feedbackMessage: message,
      feedbackIsError: isError,
      feedbackId: state.feedbackId + 1,
    );
  }
}
