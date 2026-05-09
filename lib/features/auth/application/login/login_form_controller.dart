import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_models.dart';
import '../../data/auth_providers.dart';
import '../auth_session_provider.dart';
import 'login_form_state.dart';

final loginFormControllerProvider =
    NotifierProvider<LoginFormController, LoginFormState>(
      LoginFormController.new,
    );

class LoginFormController extends Notifier<LoginFormState> {
  static final RegExp _emailPattern = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
  );

  @override
  LoginFormState build() => const LoginFormState();

  void setLoginMode(bool isPhoneLogin) {
    state = state.copyWith(isPhoneLogin: isPhoneLogin);
  }

  void setLanguageSelected(bool isChineseSelected) {
    state = state.copyWith(isChineseSelected: isChineseSelected);
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

  Future<void> sendCode() async {
    final validationError = _validateBeforeSendingCode();
    if (validationError != null) {
      _emitFeedback(validationError, isError: true);
      return;
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
        _emitFeedback('已发送短信验证码');
      } else {
        await authService.sendEmailCode(
          request: SendEmailBO(
            email: state.email.trim(),
            scene: 'login',
          ),
        );
        _emitFeedback('已发送邮箱验证码');
      }
    } catch (_) {
      _emitFeedback('验证码发送失败，请稍后重试', isError: true);
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
      return login;
    } catch (_) {
      _emitFeedback('登录失败，请检查验证码后重试', isError: true);
      return null;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  String? _validateBeforeSendingCode() {
    if (!state.agreed) {
      return '请先同意用户协议与隐私政策';
    }

    if (state.isPhoneLogin) {
      if (state.phone.trim().isEmpty) {
        return '请输入手机号';
      }
      return null;
    }

    if (state.email.trim().isEmpty) {
      return '请输入邮箱';
    }
    if (!_emailPattern.hasMatch(state.email.trim())) {
      return '请输入正确的邮箱地址';
    }
    return null;
  }

  String? _validateBeforeLogin() {
    final sendCodeError = _validateBeforeSendingCode();
    if (sendCodeError != null) {
      return sendCodeError;
    }
    if (state.code.trim().isEmpty) {
      return state.isPhoneLogin ? '请输入短信验证码' : '请输入邮箱验证码';
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
