const Object _feedbackSentinel = Object();

class LoginFormState {
  const LoginFormState({
    this.isPhoneLogin = true,
    this.isChineseSelected = true,
    this.agreed = false,
    this.regionCode = '+86',
    this.phone = '',
    this.email = '',
    this.code = '',
    this.isSendingCode = false,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackId = 0,
  });

  final bool isPhoneLogin;
  final bool isChineseSelected;
  final bool agreed;
  final String regionCode;
  final String phone;
  final String email;
  final String code;
  final bool isSendingCode;
  final bool isSubmitting;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackId;

  String get currentAccount => isPhoneLogin ? phone.trim() : email.trim();

  bool get canSendCode => currentAccount.isNotEmpty && !isSendingCode && !isSubmitting;

  bool get canLogin =>
      agreed && currentAccount.isNotEmpty && code.trim().isNotEmpty && !isSubmitting;

  LoginFormState copyWith({
    bool? isPhoneLogin,
    bool? isChineseSelected,
    bool? agreed,
    String? regionCode,
    String? phone,
    String? email,
    String? code,
    bool? isSendingCode,
    bool? isSubmitting,
    Object? feedbackMessage = _feedbackSentinel,
    bool? feedbackIsError,
    int? feedbackId,
  }) {
    return LoginFormState(
      isPhoneLogin: isPhoneLogin ?? this.isPhoneLogin,
      isChineseSelected: isChineseSelected ?? this.isChineseSelected,
      agreed: agreed ?? this.agreed,
      regionCode: regionCode ?? this.regionCode,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      code: code ?? this.code,
      isSendingCode: isSendingCode ?? this.isSendingCode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage: identical(feedbackMessage, _feedbackSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackId: feedbackId ?? this.feedbackId,
    );
  }
}
