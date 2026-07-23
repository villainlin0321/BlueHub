import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../shared/legal/agreement_links.dart';
import '../../../../shared/ui/test_keys.dart';
import '../../../../shared/ui/app_colors.dart';
import '../../../../shared/payment/order_payment_config.dart';
import '../../application/login/login_form_state.dart';
import 'auth_language_switch.dart';

import 'package:europepass/shared/ui/test_style.dart';

typedef AgreementLinkOpener = Future<bool> Function(Uri uri);

class LoginRegionOption {
  const LoginRegionOption({required this.label, required this.code});

  final String label;
  final String code;
}

class LoginPhoneView extends StatelessWidget {
  const LoginPhoneView({
    super.key,
    required this.state,
    required this.isChineseSelected,
    required this.phoneController,
    required this.emailController,
    required this.codeController,
    required this.onRegionTap,
    required this.onLanguageChanged,
    required this.onLoginModeChanged,
    required this.onPhoneChanged,
    required this.onEmailChanged,
    required this.onCodeChanged,
    required this.onSendCode,
    required this.onLogin,
    required this.onTestWorkerLogin,
    required this.onTestServiceProviderLogin,
    required this.onTestEmployerLogin,
    required this.onAgreementChanged,
    this.onOpenAgreementLink,
  });

  final LoginFormState state;
  final bool isChineseSelected;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController codeController;
  final VoidCallback onRegionTap;
  final ValueChanged<bool> onLanguageChanged;
  final ValueChanged<bool> onLoginModeChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onCodeChanged;
  final VoidCallback onSendCode;
  final VoidCallback onLogin;
  final VoidCallback onTestWorkerLogin;
  final VoidCallback onTestServiceProviderLogin;
  final VoidCallback onTestEmployerLogin;
  final ValueChanged<bool> onAgreementChanged;
  final AgreementLinkOpener? onOpenAgreementLink;

  @override
  /// 构建登录视图，并根据当前全局语言实时切换页面文案。
  Widget build(BuildContext context) {
    final bool isReviewMode = OrderPaymentConfig.isReviewMode;
    final bool isPhoneLogin = !isReviewMode && state.isPhoneLogin;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 10, 32, 18),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerRight,
                    child: AuthLanguageSwitch(
                      isChineseSelected: isChineseSelected,
                      onChanged: onLanguageChanged,
                    ),
                  ),
                  const SizedBox(height: 50),
                  Text(
                    '认证.注册登录'.tr(),
                    style: TestStyle.pingFangSemibold(
                      fontSize: 26,
                      color: const Color(0xFF262626),
                    ),
                  ),
                  const SizedBox(height: 41),
                  if (!isReviewMode)
                    _LoginModeTabs(
                      isPhoneLogin: state.isPhoneLogin,
                      onChanged: onLoginModeChanged,
                    ),
                  const SizedBox(height: 32),
                  if (isPhoneLogin)
                    _PhoneInputRow(
                      regionCode: state.regionCode,
                      controller: phoneController,
                      onRegionTap: onRegionTap,
                      onChanged: onPhoneChanged,
                    )
                  else
                    _TextInputRow(
                      hintText: '认证.请输入邮箱'.tr(),
                      keyboardType: TextInputType.emailAddress,
                      controller: emailController,
                      onChanged: onEmailChanged,
                    ),
                  const SizedBox(height: 25),
                  _CodeInputRow(
                    hintText: isPhoneLogin
                        ? '认证.请输入验证码'.tr()
                        : '认证.请输入邮箱验证码'.tr(),
                    controller: codeController,
                    isSending: state.isSendingCode,
                    countdownSeconds: state.resendCountdownSeconds,
                    onChanged: onCodeChanged,
                    onGetCode: onSendCode,
                  ),
                  if (kDebugMode) ...<Widget>[
                    const SizedBox(height: 48),
                    _LoginButton(
                      key: AppTestKeys.loginTestJobSeekerButton,
                      label: '认证.测试登录求职者'.tr(),
                      enabled: !state.isSendingCode && !state.isSubmitting,
                      onPressed: onTestWorkerLogin,
                    ),
                    const SizedBox(height: 12),
                    _LoginButton(
                      key: AppTestKeys.loginTestServiceProviderButton,
                      label: '认证.测试登录服务商'.tr(),
                      enabled: !state.isSendingCode && !state.isSubmitting,
                      onPressed: onTestServiceProviderLogin,
                    ),
                    const SizedBox(height: 12),
                    _LoginButton(
                      label: '认证.测试登录雇主'.tr(),
                      enabled: !state.isSendingCode && !state.isSubmitting,
                      onPressed: onTestEmployerLogin,
                    ),
                  ],
                  const SizedBox(height: 48),
                  _LoginButton(
                    label: state.isSubmitting ? '认证.登录中'.tr() : '认证.登录'.tr(),
                    enabled: state.canLogin && !state.isSendingCode,
                    onPressed: onLogin,
                  ),
                  const SizedBox(height: 20),
                  _AgreementSection(
                    agreed: state.agreed,
                    onAgreementChanged: onAgreementChanged,
                    onOpenLink: (uri) =>
                        (onOpenAgreementLink ??
                        (value) => AgreementLinks.open(context, value))(uri),
                  ),
                  const Spacer(),
                  // const SizedBox(height: 24),
                  // const _SocialLoginSection(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AgreementSection extends StatefulWidget {
  const _AgreementSection({
    required this.agreed,
    required this.onAgreementChanged,
    required this.onOpenLink,
  });

  final bool agreed;
  final ValueChanged<bool> onAgreementChanged;
  final AgreementLinkOpener onOpenLink;

  @override
  State<_AgreementSection> createState() => _AgreementSectionState();
}

class _AgreementSectionState extends State<_AgreementSection> {
  late final TapGestureRecognizer _toggleAgreementRecognizer;
  late final TapGestureRecognizer _userTermsRecognizer;
  late final TapGestureRecognizer _crossTermsRecognizer;
  late final TapGestureRecognizer _privacyPolicyRecognizer;

  @override
  void initState() {
    super.initState();
    _toggleAgreementRecognizer = TapGestureRecognizer();
    _userTermsRecognizer = TapGestureRecognizer();
    _crossTermsRecognizer = TapGestureRecognizer();
    _privacyPolicyRecognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _toggleAgreementRecognizer.dispose();
    _userTermsRecognizer.dispose();
    _crossTermsRecognizer.dispose();
    _privacyPolicyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _toggleAgreementRecognizer.onTap = () =>
        widget.onAgreementChanged(!widget.agreed);
    _userTermsRecognizer.onTap = () =>
        widget.onOpenLink(AgreementLinks.userTermsUri);
    _crossTermsRecognizer.onTap = () =>
        widget.onOpenLink(AgreementLinks.crossBorderTermsUri);
    _privacyPolicyRecognizer.onTap = () =>
        widget.onOpenLink(AgreementLinks.privacyPolicyUri);

    final String languageCode =
        Localizations.maybeLocaleOf(context)?.languageCode.toLowerCase() ??
        'zh';
    final bool isChinese = languageCode == 'zh';
    final TextStyle plainStyle = Theme.of(context).textTheme.bodySmall!
        .copyWith(
          height: 22 / 12,
          color: const Color(0xFF171A1D),
          fontSize: 12,
        );
    final TextStyle linkStyle = TestStyle.pingFangRegular(
      color: AppColors.brand,
    ).copyWith(height: 22 / 12, fontSize: 12);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: _AgreementCheckbox(
            value: widget.agreed,
            onChanged: widget.onAgreementChanged,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: RichText(
            key: const Key('login_agreement_rich_text'),
            text: TextSpan(
              style: plainStyle,
              children: <InlineSpan>[
                TextSpan(
                  text: '认证.协议前缀'.tr(),
                  recognizer: _toggleAgreementRecognizer,
                ),
                TextSpan(
                  text: '认证.用户服务协议'.tr(),
                  style: linkStyle,
                  recognizer: _userTermsRecognizer,
                ),
                TextSpan(text: isChinese ? '、' : ', '),
                TextSpan(
                  text: '认证.个人信息跨境流动用户协议'.tr(),
                  style: linkStyle,
                  recognizer: _crossTermsRecognizer,
                ),
                TextSpan(text: isChinese ? '和' : ', and '),
                TextSpan(
                  text: '认证.用户隐私政策'.tr(),
                  style: linkStyle,
                  recognizer: _privacyPolicyRecognizer,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LoginModeTabs extends StatelessWidget {
  const _LoginModeTabs({required this.isPhoneLogin, required this.onChanged});

  final bool isPhoneLogin;
  final ValueChanged<bool> onChanged;

  @override
  /// 构建登录方式切换标签，支持手机号和邮箱两种方式。
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _ModeTab(
              label: '认证.手机号'.tr(),
              selected: isPhoneLogin,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 24),
            _ModeTab(
              label: '认证.邮箱'.tr(),
              selected: !isPhoneLogin,
              onTap: () => onChanged(false),
            ),
          ],
        ),
        const SizedBox(height: 4),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(left: isPhoneLogin ? 1 : 61),
          width: 40,
          height: 2,
          color: AppColors.brand,
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  /// 构建单个登录方式标签，并根据选中态切换颜色。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          label,
          style: TestStyle.medium(
            fontSize: 14,
            color: selected ? AppColors.brand : const Color(0xFF8C8C8C),
          ),
        ),
      ),
    );
  }
}

class _PhoneInputRow extends StatelessWidget {
  const _PhoneInputRow({
    required this.regionCode,
    required this.controller,
    required this.onRegionTap,
    this.onChanged,
  });

  final String regionCode;
  final TextEditingController controller;
  final VoidCallback onRegionTap;
  final ValueChanged<String>? onChanged;

  @override
  /// 构建手机号输入行，左侧展示当前区号并支持弹出地区选择器。
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            InkWell(
              onTap: onRegionTap,
              child: Padding(
                padding: const EdgeInsets.only(left: 3, top: 2, bottom: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      regionCode,
                      style: TestStyle.regular(
                        fontSize: 16,
                        color: const Color(0xFF262626),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Color(0xFF595959),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: '认证.请输入手机号'.tr(),
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TestStyle.pingFangRegular(
                    fontSize: 16,
                    color: Color(0xFFBFBFBF),
                  ),
                ),
                style: TestStyle.regular(
                  fontSize: 16,
                  color: Color(0xFF262626),
                ),
                onChanged: onChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}

class _TextInputRow extends StatelessWidget {
  const _TextInputRow({
    required this.hintText,
    required this.keyboardType,
    required this.controller,
    this.onChanged,
  });

  final String hintText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  /// 构建通用文本输入行，用于邮箱等单字段输入场景。
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            isDense: true,
            border: InputBorder.none,
            hintStyle: TestStyle.regular(
              fontSize: 16,
              color: Color(0xFFBFBFBF),
            ),
          ),
          style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}

class _CodeInputRow extends StatelessWidget {
  const _CodeInputRow({
    required this.hintText,
    required this.controller,
    required this.isSending,
    required this.countdownSeconds,
    required this.onGetCode,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController controller;
  final bool isSending;
  final int countdownSeconds;
  final VoidCallback onGetCode;
  final ValueChanged<String>? onChanged;

  @override
  /// 构建验证码输入行，并在右侧承载发送验证码按钮。
  Widget build(BuildContext context) {
    final isCountdownActive = countdownSeconds > 0;
    final isActionDisabled = isSending || isCountdownActive;
    final actionWidget = isSending
        ? const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
            ),
          )
        : Text(
            isCountdownActive
                ? '认证.秒后重发'.tr(namedArgs: {'seconds': '$countdownSeconds'})
                : '认证.获取验证码'.tr(),
            style: TestStyle.pingFangRegular(
              fontSize: 14,
              color: isActionDisabled
                  ? const Color(0xFFBFBFBF)
                  : AppColors.brand,
            ),
          );

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TestStyle.regular(
                    fontSize: 16,
                    color: Color(0xFFBFBFBF),
                  ),
                ),
                style: TestStyle.regular(
                  fontSize: 16,
                  color: Color(0xFF262626),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isActionDisabled ? null : onGetCode,
              child: actionWidget,
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 1, color: Color(0xFFD8D8D8)),
      ],
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  /// 构建登录主按钮，并统一处理启用态与禁用态样式。
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF096DD9),
          disabledBackgroundColor: const Color(
            0xFF096DD9,
          ).withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          label,
          style: TestStyle.regular(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}

class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  /// 构建协议勾选框，并把点击结果回传给父级状态。
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      customBorder: const CircleBorder(),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: value ? AppColors.brand : const Color(0xFFBFBFBF),
            width: 2,
          ),
          color: value ? AppColors.brand : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: value
            ? const Icon(Icons.check_rounded, size: 11, color: Colors.white)
            : null,
      ),
    );
  }
}

class RegionPickerSheet extends StatelessWidget {
  const RegionPickerSheet({
    super.key,
    required this.options,
    required this.selected,
  });

  final List<LoginRegionOption> options;
  final LoginRegionOption selected;

  @override
  /// 构建地区选择底部弹层，并高亮当前已选择的区号。
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '认证.选择地区'.tr(),
              style: TestStyle.pingFangSemibold(
                fontSize: 16,
                color: const Color(0xFF262626),
              ),
            ),
            const SizedBox(height: 8),
            ...options.map((option) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(option.label),
                subtitle: Text(option.code),
                trailing: option == selected
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              );
            }),
          ],
        ),
      ),
    );
  }
}
