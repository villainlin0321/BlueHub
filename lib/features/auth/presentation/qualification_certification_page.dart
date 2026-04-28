import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'widgets/qualification_progress_stepper.dart';

class QualificationCertificationPage extends StatefulWidget {
  const QualificationCertificationPage({super.key});

  @override
  State<QualificationCertificationPage> createState() =>
      _QualificationCertificationPageState();
}

class _QualificationCertificationPageState
    extends State<QualificationCertificationPage> {
  static const List<String> _steps = <String>[
    '基本信息',
    '资质证明',
    '服务信息',
  ];

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _creditCodeController = TextEditingController();
  final TextEditingController _legalPersonController = TextEditingController();
  final TextEditingController _contactPersonController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  @override
  void dispose() {
    _companyNameController.dispose();
    _creditCodeController.dispose();
    _legalPersonController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _showPlaceholderMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: const Text(
          '资质认证',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '为了您的企业账户安全，请完成实名认证',
                  style: TextStyle(
                    color: Color(0xFF8C8C8C),
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: QualificationProgressStepper(
                  labels: _steps,
                  currentStep: 1,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _FormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _QualificationTextField(
                        label: '企业名称',
                        hintText: '请输入营业执照上的企业全称',
                        controller: _companyNameController,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _QualificationTextField(
                        label: '统一社会信用代码',
                        hintText: '请输入',
                        controller: _creditCodeController,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _QualificationTextField(
                        label: '法人姓名',
                        hintText: '请输入',
                        controller: _legalPersonController,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _SectionLabel(label: '法人身份证', required: true),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _UploadCard(
                              imageAsset:
                                  'assets/images/qualification_id_emblem.png',
                              label: '上传国徽面',
                              onTap: () => _showPlaceholderMessage('上传国徽面（占位）'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _UploadCard(
                              imageAsset:
                                  'assets/images/qualification_id_portrait.png',
                              label: '上传人像面',
                              onTap: () => _showPlaceholderMessage('上传人像面（占位）'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _QualificationTextField(
                        label: '官方联系人',
                        hintText: '请输入',
                        controller: _contactPersonController,
                        required: true,
                      ),
                      const SizedBox(height: 16),
                      _QualificationTextField(
                        label: '联系电话',
                        hintText: '请输入',
                        controller: _phoneController,
                        required: true,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _QualificationTextField(
                        label: '邮箱',
                        hintText: '请输入',
                        controller: _emailController,
                        required: true,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _QualificationTextField(
                        label: '公司官网',
                        hintText: '选填',
                        controller: _websiteController,
                        keyboardType: TextInputType.url,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFF0F0F0)),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => context.push(RoutePaths.qualificationCertificationStepTwo),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF096DD9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                '下一步',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 22 / 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    this.required = false,
  });

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF262626),
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
        if (required) ...<Widget>[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFFF4D4F),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 20 / 14,
            ),
          ),
        ],
      ],
    );
  }
}

class _QualificationTextField extends StatelessWidget {
  const _QualificationTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    this.required = false,
    this.keyboardType,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(label: label, required: required),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 48,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textAlignVertical: TextAlignVertical.center,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 14,
                height: 20 / 14,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: Color(0xFFBFBFBF),
                  fontSize: 14,
                  height: 20 / 14,
                ),
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.imageAsset,
    required this.label,
    required this.onTap,
  });

  final String imageAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: <Widget>[
          Container(
            height: 116,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              imageAsset,
              width: 159,
              height: 116,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ],
      ),
    );
  }
}
