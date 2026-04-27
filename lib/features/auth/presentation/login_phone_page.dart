import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'widgets/auth_language_switch.dart';

/// 手机号登录页（按 Figma 截图还原，先用本地校验与跳转占位）。
class LoginPhonePage extends StatefulWidget {
  const LoginPhonePage({super.key});

  @override
  State<LoginPhonePage> createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends State<LoginPhonePage> {
  static const _regionOptions = <_RegionOption>[
    _RegionOption(label: '中国大陆', code: '+86'),
    _RegionOption(label: '中国香港', code: '+852'),
    _RegionOption(label: '中国澳门', code: '+853'),
    _RegionOption(label: '新加坡', code: '+65'),
  ];

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isPhoneLogin = true;
  bool _isChineseSelected = true;
  bool _agreed = false;
  _RegionOption _selectedRegion = _regionOptions.first;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _canLogin {
    final account = _isPhoneLogin
        ? _phoneController.text.trim()
        : _emailController.text.trim();
    final code = _codeController.text.trim();
    return _agreed && account.isNotEmpty && code.isNotEmpty;
  }

  Future<void> _showRegionPicker() async {
    final region = await showModalBottomSheet<_RegionOption>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _RegionPickerSheet(
        options: _regionOptions,
        selected: _selectedRegion,
      ),
    );

    if (region != null) {
      setState(() => _selectedRegion = region);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: TapBlankToDismissKeyboard(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 10, 32, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 28,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Align(
                          alignment: Alignment.centerRight,
                          child: AuthLanguageSwitch(
                            isChineseSelected: _isChineseSelected,
                            onChanged: (isChineseSelected) {
                              setState(() {
                                _isChineseSelected = isChineseSelected;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 50),
                        Text(
                          '注册/登录',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: const Color(0xFF262626),
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 41),
                        _LoginModeTabs(
                          isPhoneLogin: _isPhoneLogin,
                          onChanged: (isPhoneLogin) {
                            setState(() => _isPhoneLogin = isPhoneLogin);
                          },
                        ),
                        const SizedBox(height: 32),
                        if (_isPhoneLogin)
                          _PhoneInputRow(
                            regionCode: _selectedRegion.code,
                            controller: _phoneController,
                            onRegionTap: _showRegionPicker,
                            onChanged: (_) => setState(() {}),
                          )
                        else
                          _TextInputRow(
                            hintText: '请输入邮箱',
                            keyboardType: TextInputType.emailAddress,
                            controller: _emailController,
                            onChanged: (_) => setState(() {}),
                          ),
                        const SizedBox(height: 25),
                        _CodeInputRow(
                          hintText: _isPhoneLogin ? '请输入验证码' : '请输入邮箱验证码',
                          controller: _codeController,
                          onChanged: (_) => setState(() {}),
                          onGetCode: () {
                            final message = _isPhoneLogin
                                ? '已发送短信验证码（占位）'
                                : '已发送邮箱验证码（占位）';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(message)),
                            );
                          },
                        ),
                        const SizedBox(height: 48),
                        _LoginButton(
                          label: '登录',
                          enabled: _canLogin,
                          onPressed: () {
                            // 当前阶段只跑通页面流，登录成功后直接进入主 Tab。
                            context.go(RoutePaths.home);
                          },
                        ),
                        const SizedBox(height: 20),
                        InkWell(
                          onTap: () => setState(() => _agreed = !_agreed),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              _AgreementCheckbox(
                                value: _agreed,
                                onChanged: (value) {
                                  setState(() => _agreed = value);
                                },
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          height: 22 / 12,
                                          color: const Color(0xFF171A1D),
                                          fontSize: 12,
                                        ),
                                    children: const <InlineSpan>[
                                      TextSpan(text: '同意'),
                                      TextSpan(
                                        text: '《XXXA用户服务协议》《XXXA用户隐私政策》',
                                        style: TextStyle(color: AppColors.brand),
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
          ),
        ),
      ),
    );
  }
}

class _LoginModeTabs extends StatelessWidget {
  const _LoginModeTabs({
    required this.isPhoneLogin,
    required this.onChanged,
  });

  final bool isPhoneLogin;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            _ModeTab(
              label: '手机号',
              selected: isPhoneLogin,
              onTap: () => onChanged(true),
            ),
            const SizedBox(width: 24),
            _ModeTab(
              label: '邮箱',
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
                decoration: const InputDecoration(
                  hintText: '请输入手机号',
                  isDense: true,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Color(0xFFBFBFBF),
                    fontSize: 16,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
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
            hintStyle: const TextStyle(
              color: Color(0xFFBFBFBF),
              fontSize: 16,
            ),
          ),
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 16,
          ),
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
    required this.onGetCode,
    this.onChanged,
  });

  final String hintText;
  final TextEditingController controller;
  final VoidCallback onGetCode;
  final ValueChanged<String>? onChanged;

  @override
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
                  hintStyle: const TextStyle(
                    color: Color(0xFFBFBFBF),
                    fontSize: 16,
                  ),
                ),
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onGetCode,
              child: Text(
                '获取验证码',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.brand,
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
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF096DD9),
          disabledBackgroundColor: const Color(0xFF096DD9).withValues(alpha: 0.45),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
  const _AgreementCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
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

class _RegionPickerSheet extends StatelessWidget {
  const _RegionPickerSheet({
    required this.options,
    required this.selected,
  });

  final List<_RegionOption> options;
  final _RegionOption selected;

  @override
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
              '选择地区',
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

class _RegionOption {
  const _RegionOption({
    required this.label,
    required this.code,
  });

  final String label;
  final String code;
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon, {required this.size});

  final IconData icon;
  final double size;

  @override
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
