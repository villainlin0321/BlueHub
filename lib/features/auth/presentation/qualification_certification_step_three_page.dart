import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'widgets/qualification_progress_stepper.dart';

class QualificationCertificationStepThreePage extends StatefulWidget {
  const QualificationCertificationStepThreePage({super.key});

  @override
  State<QualificationCertificationStepThreePage> createState() =>
      _QualificationCertificationStepThreePageState();
}

class _QualificationCertificationStepThreePageState
    extends State<QualificationCertificationStepThreePage> {
  static const List<String> _steps = <String>[
    '基本信息',
    '资质证明',
    '服务信息',
  ];

  static const List<String> _selectedCountries = <String>[
    '德国',
    '意大利',
    '法国',
  ];

  final TextEditingController _experienceController = TextEditingController();

  @override
  void dispose() {
    _experienceController.dispose();
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
                  currentStep: 3,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text(
                            '期望国家/地区',
                            style: TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 22 / 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '(可多选)',
                            style: TextStyle(
                              color: Color(0xFF8C8C8C),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 18 / 13,
                            ),
                          ),
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
                          const Spacer(),
                          InkWell(
                            onTap: () => _showPlaceholderMessage('新增国家/地区（占位）'),
                            borderRadius: BorderRadius.circular(10),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: Center(
                                child: SvgPicture.asset(
                                  'assets/images/qualification_add.svg',
                                  width: 12,
                                  height: 12,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0x99262626),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCountries
                            .map(
                              (String country) => _CountryTag(
                                label: country,
                                onTap: () => _showPlaceholderMessage('移除$country（占位）'),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: <Widget>[
                          Text(
                            '从业年限',
                            style: TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 20 / 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            '*',
                            style: TextStyle(
                              color: Color(0xFFFF4D4F),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 20 / 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F7FA),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _experienceController,
                                keyboardType: TextInputType.number,
                                textAlignVertical: TextAlignVertical.center,
                                style: const TextStyle(
                                  color: Color(0xFF262626),
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '请输入',
                                  hintStyle: TextStyle(
                                    color: Color(0xFFBFBFBF),
                                    fontSize: 14,
                                    height: 20 / 14,
                                  ),
                                  border: InputBorder.none,
                                  isCollapsed: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '年',
                            style: TextStyle(
                              color: Color(0xFF262626),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 20 / 14,
                            ),
                          ),
                        ],
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
          child: Row(
            children: <Widget>[
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD9D9D9)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '上一步',
                      style: TextStyle(
                        color: Color(0xFF171A1D),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () => _showPlaceholderMessage('提交审核（占位）'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF096DD9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '提交审核',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 22 / 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryTag extends StatelessWidget {
  const _CountryTag({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDF4FF),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF91C3FF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF096DD9),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 18 / 14,
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/qualification_tag_close.svg',
              width: 9,
              height: 9,
            ),
          ],
        ),
      ),
    );
  }
}
