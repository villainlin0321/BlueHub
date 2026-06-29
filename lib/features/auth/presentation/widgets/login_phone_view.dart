import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/ui/app_colors.dart';
import '../../application/login/login_form_state.dart';
import 'auth_language_switch.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
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

  @override
  /// 构建登录视图，并根据当前全局语言实时切换页面文案。
  Widget build(BuildContext context) {
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF262626),
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 41),
                  _LoginModeTabs(
                    isPhoneLogin: state.isPhoneLogin,
                    onChanged: onLoginModeChanged,
                  ),
                  const SizedBox(height: 32),
                  if (state.isPhoneLogin)
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
                    hintText: state.isPhoneLogin
                        ? '认证.请输入验证码'.tr()
                        : '认证.请输入邮箱验证码'.tr(),
                    controller: codeController,
                    isSending: state.isSendingCode,
                    onChanged: onCodeChanged,
                    onGetCode: onSendCode,
                  ),
                  const SizedBox(height: 48),
                  _LoginButton(
                    label: '认证.测试登录求职者'.tr(),
                    enabled: !state.isSendingCode && !state.isSubmitting,
                    onPressed: onTestWorkerLogin,
                  ),
                  const SizedBox(height: 12),
                  _LoginButton(
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
                  const SizedBox(height: 48),
                  _LoginButton(
                    label: state.isSubmitting ? '认证.登录中'.tr() : '认证.登录'.tr(),
                    enabled: state.canLogin && !state.isSendingCode,
                    onPressed: onLogin,
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: () => onAgreementChanged(!state.agreed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _AgreementCheckbox(
                          value: state.agreed,
                          onChanged: onAgreementChanged,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    height: 22 / 12,
                                    color: const Color(0xFF171A1D),
                                    fontSize: 12,
                                  ),
                              children: <InlineSpan>[
                                TextSpan(text: '认证.协议前缀'.tr()),
                                TextSpan(
                                  text:
                                      '${'认证.用户服务协议'.tr()}${'认证.用户隐私政策'.tr()}',
                                  style: const TextStyle(
                                    color: AppColors.brand,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 24),
                  const _SocialLoginSection(),
                ],
              ),
            ),
          ),
        );
      },
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: selected ? AppColors.brand : const Color(0xFF8C8C8C),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF262626),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
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
                  hintStyle: TestStyle.pingFangRegular(fontSize: 16, color: Color(0xFFBFBFBF)),
                ),
                style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
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
            hintStyle: TestStyle.regular(fontSize: 16, color: Color(0xFFBFBFBF)),
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
    required this.onGetCode,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onGetCode;
  final ValueChanged<String>? onChanged;

  @override
  /// 构建验证码输入行，并在右侧承载发送验证码按钮。
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: hintText,
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TestStyle.regular(fontSize: 16, color: Color(0xFFBFBFBF)),
                ),
                style: TestStyle.regular(fontSize: 16, color: Color(0xFF262626)),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isSending ? null : onGetCode,
              child: Text(
                isSending ? '认证.发送中'.tr() : '认证.获取验证码'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSending
                      ? AppColors.brand.withValues(alpha: 0.45)
                      : AppColors.brand,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
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

class _LoginButton extends StatelessWidget {
  const _LoginButton({
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
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

class _SocialLoginSection extends StatelessWidget {
  const _SocialLoginSection();

  @override
  /// 构建底部第三方登录图标区，目前保留为纯展示入口。
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _SocialIcon(Icons.g_mobiledata, size: 24),
        SizedBox(width: 22),
        _SocialIcon(Icons.apple, size: 21),
        SizedBox(width: 22),
        _SocialIcon(Icons.wechat, size: 24),
      ],
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF262626),
                fontWeight: FontWeight.w600,
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

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon, {required this.size});

  final IconData icon;
  final double size;

  @override
  /// 构建单个社交登录图标容器，统一圆形边框与居中布局。
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFBFBFBF)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size, color: AppColors.textSecondary),
    );
  }
}
