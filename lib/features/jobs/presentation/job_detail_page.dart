import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/widgets/app_svg_icon.dart';

class JobDetailPage extends StatelessWidget {
  const JobDetailPage({super.key});

  static const String _companyAvatarAsset =
      'assets/images/job_detail_company_avatar.png';
  static const String _mapAsset = 'assets/images/job_detail_map-56586a.png';
  static const List<String> _jobTags = <String>['3-5年经验', '厨师证高级', '提供签证'];
  static const List<String> _responsibilities = <String>[
    '1. 负责餐厅热菜制作，保证菜品质量与口味稳定；',
    '2. 协助主厨进行新菜品研发，特别是川菜系列；',
    '3. 负责后厨卫生与食材管理，严格控制成本。',
  ];
  static const List<String> _requirements = <String>[
    '1. 具备3年以上中餐炒锅经验，擅长川菜者优先；',
    '2. 必须持有国家认可的《中式烹调师》高级及以上证书（用于办理签证）；',
    '3. 无犯罪记录，身体健康，能吃苦耐劳；',
    '4. 无需德语基础，餐厅提供中文工作环境。',
  ];
  static const List<String> _benefits = <String>[
    '1. 提供免费食宿（独立单间）；',
    '2. 餐厅协助办理德国工作签证（费用可协商报销）；',
    '3. 每年享有20天带薪年假。',
  ];

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.jobs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => _handleBack(context),
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF262626),
          ),
        ),
        title: Text(
          '招聘详情',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: <Widget>[
          IconButton(
            onPressed: () => _showMessage(context, '收藏功能开发中'),
            icon: const AppSvgIcon(
              assetPath: 'assets/images/service_detail_favorite.svg',
              fallback: Icons.star_border_rounded,
              size: 20,
              color: Color(0xFF262626),
            ),
          ),
          IconButton(
            onPressed: () => _showMessage(context, '分享功能开发中'),
            icon: const AppSvgIcon(
              assetPath: 'assets/images/service_detail_share.svg',
              fallback: Icons.share_outlined,
              size: 20,
              color: Color(0xFF262626),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: const <Widget>[
          _JobHeaderSection(),
          SizedBox(height: 1),
          _EmployerCard(avatarAssetPath: _companyAvatarAsset),
          SizedBox(height: 1),
          _JobDescriptionSection(),
          SizedBox(height: 1),
          _LocationSection(mapAssetPath: _mapAsset),
        ],
      ),
      bottomNavigationBar: _BottomActionBar(
        onChatTap: () => _showMessage(context, '立即沟通（占位）'),
        onApplyTap: () => _showMessage(context, '投递简历（占位）'),
      ),
    );
  }
}

class _JobHeaderSection extends StatelessWidget {
  const _JobHeaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  '中餐厨师 (包食宿)',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    height: 30 / 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '€2,500~3,500',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFFFE5815),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  height: 24 / 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: JobDetailPage._jobTags
                .map((String tag) => _BorderTag(label: tag))
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Color(0xFFBCBCBC),
              ),
              const SizedBox(width: 4),
              Text(
                '德国·柏林',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF595959),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 16 / 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BorderTag extends StatelessWidget {
  const _BorderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFA3AFD4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF546D96),
          fontWeight: FontWeight.w400,
          fontSize: 10,
          height: 1,
        ),
      ),
    );
  }
}

class _EmployerCard extends StatelessWidget {
  const _EmployerCard({required this.avatarAssetPath});

  final String avatarAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: Image.asset(
              avatarAssetPath,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '柏林老四川餐厅',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF262626),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    height: 24 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '餐饮行业·50-100人',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8C8C8C),
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 16 / 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFFBFBFBF),
          ),
        ],
      ),
    );
  }
}

class _JobDescriptionSection extends StatelessWidget {
  const _JobDescriptionSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '职位详情',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF262626),
              fontWeight: FontWeight.w600,
              fontSize: 18,
              height: 26 / 18,
            ),
          ),
          const SizedBox(height: 12),
          const _DescriptionBlock(
            title: '岗位职责：',
            items: JobDetailPage._responsibilities,
          ),
          const SizedBox(height: 20),
          const _DescriptionBlock(
            title: '任职要求：',
            items: JobDetailPage._requirements,
          ),
          const SizedBox(height: 20),
          const _DescriptionBlock(
            title: '福利待遇：',
            items: JobDetailPage._benefits,
          ),
        ],
      ),
    );
  }
}

class _DescriptionBlock extends StatelessWidget {
  const _DescriptionBlock({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF262626),
            fontWeight: FontWeight.w500,
            fontSize: 14,
            height: 26 / 14,
          ),
        ),
        for (final String item in items)
          Text(
            item,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF595959),
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 26 / 14,
            ),
          ),
      ],
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({required this.mapAssetPath});

  final String mapAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '工作地点',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF262626),
              fontWeight: FontWeight.w500,
              fontSize: 16,
              height: 24 / 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '德国柏林市中心 Mitte 区',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              mapAssetPath,
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.onChatTap, required this.onApplyTap});

  final VoidCallback onChatTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: const Color(0xFF171A1D),
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 22 / 16,
    );
    final primaryStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 22 / 16,
    );

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 169,
              child: OutlinedButton(
                onPressed: onChatTap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Color(0xFFD9D9D9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text('立即沟通', style: secondaryStyle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 170,
              child: FilledButton(
                onPressed: onApplyTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('投递简历', style: primaryStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
