import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../auth/presentation/qualification_certification_flow.dart';

/// 服务商“我的信息”页，按 Figma 设计稿实现静态占位展示。
class ServiceProviderMyInfoPage extends StatelessWidget {
  const ServiceProviderMyInfoPage({super.key});

  static const String _logoAsset = 'assets/images/mou588hj-vpl779h.png';
  static const List<_InfoItem> _infoItems = <_InfoItem>[
    _InfoItem(label: '企业名称', value: '中欧出海签证服务'),
    _InfoItem(label: '统一社会\n信用代码', value: 'CKHR87982937938497'),
    _InfoItem(label: '法人姓名', value: '王晓晓'),
    _InfoItem(label: '官方联系人', value: '王晓霞'),
    _InfoItem(label: '联系电话', value: '13290867643'),
    _InfoItem(label: '邮箱', value: 'lksdoieu@126.com'),
    _InfoItem(label: '官网', value: 'www.idsfoi948.com'),
    _InfoItem(label: '从业年限', value: '12'),
    _InfoItem(label: '国家/地区', value: '德国/意大利/法国'),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _Header(onBackTap: context.pop),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _InfoSection(items: _infoItems),
                    const SizedBox(height: 12),
                    const _QualificationSection(),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '注意：修改企业信息后需要重新提交审核，请确保xxxx当前业务是否都处理完成。',
                        style: TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                          height: 18 / 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _BottomActionBar(
              bottomInset: bottomInset,
              onTap: () => context.push(
                RoutePaths.qualificationCertification,
                extra: QualificationCertificationPageArgs(
                  role: QualificationCertificationRole.serviceProvider,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
            ),
          ),
          const Text(
            '我的信息',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.items});

  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              '基础信息',
              style: TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 22 / 16,
              ),
            ),
          ),
          const _AvatarRow(),
          for (int index = 0; index < items.length; index++) ...<Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            ),
            _InfoRow(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  const _AvatarRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              '头像',
              style: TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
          ),
          Image.asset(
            ServiceProviderMyInfoPage._logoAsset,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 15),
      child: Row(
        crossAxisAlignment: item.label.contains('\n')
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              item.label,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualificationSection extends StatelessWidget {
  const _QualificationSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            '材料资质',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '身份证',
            style: TextStyle(
              color: Color(0xFF262626),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: <Widget>[
              Expanded(
                child: _MaterialPlaceholderCard(
                  imageAsset: 'assets/images/qualification_id_emblem.png',
                  height: 100,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _MaterialPlaceholderCard(
                  imageAsset: 'assets/images/qualification_id_portrait.png',
                  height: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _DocumentBlock(
                  label: '营业执照',
                  child: _MaterialPlaceholderCard(
                    imageAsset:
                        'assets/images/qualification_license_placeholder.png',
                    height: 110,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _DocumentBlock(
                  label: '特许经验许可',
                  child: _MaterialPlaceholderCard(
                    imageAsset:
                        'assets/images/qualification_license_placeholder.png',
                    height: 110,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentBlock extends StatelessWidget {
  const _DocumentBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _MaterialPlaceholderCard extends StatelessWidget {
  const _MaterialPlaceholderCard({
    required this.imageAsset,
    required this.height,
  });

  final String imageAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD9D9D9),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imageAsset,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.bottomInset, required this.onTap});

  final double bottomInset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 20),
      child: SizedBox(
        height: 44,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
          child: const Text('修改信息'),
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}
