import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:europepass/shared/ui/test_style.dart';
/// 关于我们页：用于展示应用名称、版本信息以及公司主体信息，便于留存合规截图。
class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  static const String _companyName = '南京云合智聘人力资源有限公司';
  static const String _creditCode = '91320118MAK86HKW9K';
  static const String _appIconAsset =
      'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png';

  String _versionLabel = '--';

  @override
  void initState() {
    super.initState();
    _loadVersionLabel();
  }

  @override
  /// 构建关于我们页，集中展示尾页截图需要的应用和公司主体信息。
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('关于页.标题'.tr()),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildHeaderCard(context),
              const Spacer(),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 读取当前安装包版本，组合成适合展示在“关于我们”页的版本文案。
  Future<void> _loadVersionLabel() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version.trim();
    final String buildNumber = packageInfo.buildNumber.trim();
    final String nextLabel = switch ((version.isEmpty, buildNumber.isEmpty)) {
      (true, true) => '--',
      (false, true) => 'v$version',
      (true, false) => '($buildNumber)',
      (false, false) => 'v$version ($buildNumber)',
    };
    if (!mounted) {
      return;
    }
    setState(() {
      _versionLabel = nextLabel;
    });
  }

  /// 构建顶部应用信息卡片，优先突出应用名称与版本，便于尾页截图识别。
  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              _appIconAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // 关键兜底：即使资源丢失也保留一个可截图的占位图标。
                return Container(
                  color: const Color(0xFF186CFF),
                  alignment: Alignment.center,
                  child: Text(
                    '应用.标题'.tr().characters.take(2).toString(),
                    style: TestStyle.numberBold(fontSize: 24, color: Colors.white),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '应用.标题'.tr(),
            style: TestStyle.numberBold(fontSize: 24, color: Color(0xFF262626)),
          ),
          const SizedBox(height: 8),
          Text(
            '${'关于页.版本'.tr()} $_versionLabel',
            style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF8C8C8C)),
          ),
          const SizedBox(height: 12),
          Text(
            '关于页.说明'.tr(),
            textAlign: TextAlign.center,
            style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF595959)),
          ),
        ],
      ),
    );
  }

  /// 构建公司信息卡片，重点展示开发公司名称，满足微信支付材料的尾页展示要求。
  Widget _buildCompanyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '关于页.公司信息'.tr(),
            style: TestStyle.pingFangSemibold(fontSize: 16, color: Color(0xFF262626)),
          ),
          const SizedBox(height: 16),
          _AboutInfoRow(label: '关于页.开发公司'.tr(), value: _companyName),
          const SizedBox(height: 12),
          _AboutInfoRow(label: '关于页.运营主体'.tr(), value: _companyName),
          const SizedBox(height: 12),
          _AboutInfoRow(label: '关于页.统一社会信用代码'.tr(), value: _creditCode),
        ],
      ),
    );
  }

  /// 构建底部版权区，让截图中能稳定出现公司名称和版权声明。
  Widget _buildFooter(BuildContext context) {
    final int year = DateTime.now().year;
    return Column(
      children: <Widget>[
        Text(
          '$year ${'关于页.版权'.tr()}',
          textAlign: TextAlign.center,
          style: TestStyle.pingFangRegular(fontSize: 12, color: Color(0xFF8C8C8C)),
        ),
        const SizedBox(height: 4),
        Text(
          _companyName,
          textAlign: TextAlign.center,
          style: TestStyle.regular(fontSize: 12, color: Color(0xFF8C8C8C)),
        ),
      ],
    );
  }
}

class _AboutInfoRow extends StatelessWidget {
  const _AboutInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  /// 构建关于页单行信息，统一标题和值的对齐方式，便于材料截图清晰呈现。
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TestStyle.medium(fontSize: 14, color: Color(0xFF262626)),
          ),
        ),
      ],
    );
  }
}
