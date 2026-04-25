import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/ui/app_spacing.dart';
import '../../../shared/widgets/primary_button.dart';

/// 手机号登录页（按 Figma 截图还原，先用本地校验与跳转占位）。
class LoginPhonePage extends StatefulWidget {
  const LoginPhonePage({super.key});

  @override
  State<LoginPhonePage> createState() => _LoginPhonePageState();
}

class _LoginPhonePageState extends State<LoginPhonePage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  bool _agreed = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  bool get _canLogin {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();
    return _agreed && phone.isNotEmpty && code.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const <Widget>[
                        Icon(Icons.add, size: 16, color: AppColors.brand),
                        SizedBox(width: 4),
                        Text('En', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                '注册/登录',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Text(
                    '手机号',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.brand,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 24),
                  Text(
                    '邮箱',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(height: 2, width: 44, color: AppColors.brand),
              const SizedBox(height: 18),
              _InputRow(
                prefix: '+86',
                hintText: '请输入手机号',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _InputRow(
                prefix: null,
                hintText: '请输入验证码',
                controller: _codeController,
                keyboardType: TextInputType.number,
                suffix: TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送验证码（占位）')),
                    );
                  },
                  child: const Text('获取验证码'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 22),
              PrimaryButton(
                label: '登录',
                enabled: _canLogin,
                onPressed: () {
                  // 关键点：当前阶段只跑通页面流，登录成功后直接进入主 Tab。
                  context.go(RoutePaths.home);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _agreed = !_agreed),
                child: Row(
                  children: <Widget>[
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
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
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    _SocialIcon(Icons.g_mobiledata),
                    SizedBox(width: 22),
                    _SocialIcon(Icons.apple),
                    SizedBox(width: 22),
                    _SocialIcon(Icons.wechat),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputRow extends StatelessWidget {
  const _InputRow({
    required this.prefix,
    required this.hintText,
    required this.controller,
    required this.keyboardType,
    this.suffix,
    this.onChanged,
  });

  final String? prefix;
  final String hintText;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: <Widget>[
          if (prefix != null) ...<Widget>[
            Text(
              prefix!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
          if (suffix != null) suffix!,
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider),
      ),
      child: Icon(icon, color: AppColors.textSecondary),
    );
  }
}

