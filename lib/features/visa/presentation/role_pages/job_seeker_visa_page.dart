import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../shared/widgets/visa_service_card.dart';

/// 求职者签证页。
class JobSeekerVisaPage extends StatefulWidget {
  const JobSeekerVisaPage({super.key});

  @override
  State<JobSeekerVisaPage> createState() => _JobSeekerVisaPageState();
}

class _JobSeekerVisaPageState extends State<JobSeekerVisaPage> {
  int _selectedTabIndex = 0;

  static const List<String> _tabs = <String>['推荐套餐', '德国签证', '法国签证', '意大利签证'];

  static const List<VisaServiceCardData> _cards = <VisaServiceCardData>[
    VisaServiceCardData(
      title: '德国厨师专属工作签',
      avatarAssetPath: 'assets/images/visa/mon8on2b-9hmjfiv.png',
      rating: '4.8',
      cases: '服务案例1.2K',
      tags: <String>['过签率高', '办理快'],
      description: '专注德国、法国技术工签及厨师专签办理，专注德国、法国、意大利',
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: '德国厨师专签标准包包包包包包包',
          price: '¥15,000',
          iconAssetPath: 'assets/images/visa/mon8on2b-zz8fpa6.svg',
        ),
      ],
      verified: true,
    ),
    VisaServiceCardData(
      title: '法签通个人服务',
      avatarAssetPath: 'assets/images/visa/mon8on2b-9hmjfiv.png',
      rating: '4.8',
      cases: '服务案例1.2K',
      tags: <String>['工作签', '个人旅游'],
      description: '提供法国工作签证、旅游签证办理，一对一指导',
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: '法国工作签加急',
          price: '¥18,000',
          iconAssetPath: 'assets/images/visa/mon8on2b-zz8fpa6.svg',
        ),
      ],
    ),
    VisaServiceCardData(
      title: '意游签证中心',
      avatarAssetPath: 'assets/images/visa/mon8on2b-9hmjfiv.png',
      rating: '4.8',
      cases: '服务案例1.2K',
      tags: <String>['加急办理', '材料辅导'],
      description: '意大利劳务签证、护理工定制签证服务',
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: '意大利劳务普签',
          price: '¥15,000',
          iconAssetPath: 'assets/images/visa/mon8on2b-zz8fpa6.svg',
        ),
      ],
      verified: true,
    ),
    VisaServiceCardData(
      title: '中欧出海签证服务',
      avatarAssetPath: 'assets/images/visa/mon8on2b-9hmjfiv.png',
      rating: '4.8',
      cases: '服务案例1.2K',
      tags: <String>['过签率高', '办理快'],
      description: '专注德国、法国技术工签及厨师专签办理，专注德国、法…',
      packages: <VisaServicePackageData>[
        VisaServicePackageData(
          title: '德国厨师专签标准包',
          price: '¥12,000',
          iconAssetPath: 'assets/images/visa/mon8on2b-zz8fpa6.svg',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/job_seeker_visa_header_bg.png'),
          fit: BoxFit.fitWidth,
          alignment: Alignment.topCenter,
        ),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomPadding + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _VisaHeroSection(
              selectedIndex: _selectedTabIndex,
              onTabTap: (int index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (BuildContext context, int index) {
                  return VisaServiceCard(
                    data: _cards[index],
                    onTap: () => context.push(RoutePaths.serviceDetail),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisaHeroSection extends StatelessWidget {
  const _VisaHeroSection({required this.selectedIndex, required this.onTabTap});

  final int selectedIndex;
  final ValueChanged<int> onTabTap;

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: topPadding + 13, bottom: 10, left: 20),
          child: Text(
            '服务商与签证套餐',
            style: TextStyle(
              color: Colors.black,
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: _VisaSearchBar(),
        ),
        const SizedBox(height: 14),
        _VisaTabRow(selectedIndex: selectedIndex, onTap: onTabTap),
        const SizedBox(height: 14),
      ],
    );
  }
}

class _VisaSearchBar extends StatelessWidget {
  const _VisaSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          SvgPicture.asset(
            'assets/images/visa/mon8on2b-h3091wk.svg',
            width: 16,
            height: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '搜索签证服务/欧洲岗位',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFFBFBFBF),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisaTabRow extends StatelessWidget {
  const _VisaTabRow({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 39),
        itemCount: _JobSeekerVisaPageState._tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int index) {
          final bool selected = index == selectedIndex;
          return InkWell(
            onTap: () => onTap(index),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF7AAAF4)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                _JobSeekerVisaPageState._tabs[index],
                style: TextStyle(
                  color: selected
                      ? const Color(0xFF096DD9)
                      : const Color(0xFF171A1D),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  height: 18 / 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
