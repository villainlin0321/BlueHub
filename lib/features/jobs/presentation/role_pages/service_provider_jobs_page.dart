import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 服务商套餐管理页：按 Figma「套餐管理-已上架」实现。
class ServiceProviderJobsPage extends StatefulWidget {
  const ServiceProviderJobsPage({super.key});

  @override
  State<ServiceProviderJobsPage> createState() =>
      _ServiceProviderJobsPageState();
}

class _ServiceProviderJobsPageState extends State<ServiceProviderJobsPage> {
  int _selectedTabIndex = 0;

  static const List<String> _tabs = <String>['已上架', '已下架', '已驳回'];

  static const List<_PackageCardData> _cards = <_PackageCardData>[
    _PackageCardData(
      title: '德国厨师专属工作签证',
      backgroundAssetPath: 'assets/images/jobs/mou4an3g-lktonim.svg',
      previewCountText: '浏览 342',
      tags: <String>['德国', '工作签'],
      packages: <_PackagePriceItem>[
        _PackagePriceItem(name: '基础套餐', price: '¥15,000', soldCount: 12),
        _PackagePriceItem(name: '标准套餐', price: '¥25,000', soldCount: 24),
        _PackagePriceItem(name: '尊享套餐', price: '¥36,000', soldCount: 33),
      ],
    ),
    _PackageCardData(
      title: '法国高级技术人才签',
      backgroundAssetPath: 'assets/images/jobs/mou4an3g-k9pz1oe.svg',
      previewCountText: '浏览 342',
      headerPreviewCount: '342',
      tags: <String>['法国', '技术签'],
      packages: <_PackagePriceItem>[
        _PackagePriceItem(name: '特惠套餐', price: '¥15,000', soldCount: 12),
        _PackagePriceItem(name: '标准套餐', price: '¥25,000', soldCount: 24),
      ],
      showPreviewIcon: true,
    ),
    _PackageCardData(
      title: '意大利护理工定制套餐',
      backgroundAssetPath: 'assets/images/jobs/mou4an3g-7o2wf17.svg',
      previewCountText: '浏览 342',
      tags: <String>['意大利', '工作签'],
      packages: <_PackagePriceItem>[
        _PackagePriceItem(name: '基础套餐', price: '¥15,000', soldCount: 12),
        _PackagePriceItem(name: '基础套餐', price: '¥25,000', soldCount: 24),
        _PackagePriceItem(name: '基础套餐', price: '¥36,000', soldCount: 33),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.paddingOf(context).top;
    final double bottomPadding = MediaQuery.paddingOf(context).bottom;

    return ListView(
      padding: EdgeInsets.only(bottom: bottomPadding + 8),
      children: <Widget>[
        _PageHeader(topPadding: topPadding),
        _PageTabBar(
          selectedIndex: _selectedTabIndex,
          onTap: (int index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _cards.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (BuildContext context, int index) {
              return _PackageCard(data: _cards[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.topPadding});

  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 16, 10),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '套餐管理',
              style: TextStyle(
                color: Color(0xE6000000),
                fontSize: 17,
                fontWeight: FontWeight.w500,
                height: 24 / 17,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '发布',
              style: TextStyle(
                color: Color(0xFF262626),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageTabBar extends StatelessWidget {
  const _PageTabBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: List<Widget>.generate(
          _ServiceProviderJobsPageState._tabs.length,
          (int index) {
            final bool selected = index == selectedIndex;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: EdgeInsets.only(top: 11, bottom: selected ? 0 : 11),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        _ServiceProviderJobsPageState._tabs[index],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected
                              ? const Color(0xFF096DD9)
                              : const Color(0xFF262626),
                          fontSize: 14,
                          fontWeight: selected
                              ? FontWeight.w500
                              : FontWeight.w400,
                          height: 22 / 14,
                        ),
                      ),
                      if (selected) ...<Widget>[
                        const SizedBox(height: 9),
                        Container(
                          width: 20,
                          height: 2,
                          color: const Color(0xFF096DD9),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.data});

  final _PackageCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: SvgPicture.asset(
                data.backgroundAssetPath,
                fit: BoxFit.fill,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            Flexible(
                              child: Text(
                                data.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF262626),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 24 / 16,
                                ),
                              ),
                            ),
                            if (data.showPreviewIcon &&
                                data.headerPreviewCount != null) ...<Widget>[
                              const SizedBox(width: 8),
                              SvgPicture.asset(
                                'assets/images/jobs/mou4an3g-gd04jfo.svg',
                                width: 10,
                                height: 10,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data.headerPreviewCount!,
                                style: const TextStyle(
                                  color: Color(0xFF8C8C8C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 16 / 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const _MoreIcon(),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: <Widget>[
                      ...data.tags.map(
                        (String tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _TagChip(label: tag),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        data.previewCountText,
                        style: const TextStyle(
                          color: Color(0xFF8C8C8C),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  ...List<Widget>.generate(data.packages.length, (int index) {
                    final _PackagePriceItem item = data.packages[index];
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index == data.packages.length - 1 ? 0 : 8,
                      ),
                      child: _PackagePriceRow(item: item),
                    );
                  }),
                  const SizedBox(height: 12),
                  const Row(
                    children: <Widget>[
                      _DeleteButton(),
                      Spacer(),
                      _GhostButton(label: '下架'),
                      SizedBox(width: 8),
                      _PrimaryButton(label: '编辑'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackagePriceRow extends StatelessWidget {
  const _PackagePriceRow({required this.item});

  final _PackagePriceItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          Text(
            item.name,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 20 / 12,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            item.price,
            style: const TextStyle(
              color: Color(0xFFFE5815),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 20 / 13,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 20 / 12,
              ),
              children: <InlineSpan>[
                const TextSpan(text: '已售 '),
                TextSpan(text: '${item.soldCount}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFA3AFD4), width: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF546D96),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          height: 10 / 10,
        ),
      ),
    );
  }
}

class _MoreIcon extends StatelessWidget {
  const _MoreIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: Icon(
          Icons.more_horiz_rounded,
          size: 20,
          color: Color(0xFF171A1D),
        ),
      ),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF4D4F), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        '删除',
        style: TextStyle(
          color: Color(0xFFD9363E),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD9D9D9), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF262626),
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF096DD9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 12 / 12,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PackageCardData {
  const _PackageCardData({
    required this.title,
    required this.backgroundAssetPath,
    required this.previewCountText,
    required this.tags,
    required this.packages,
    this.headerPreviewCount,
    this.showPreviewIcon = false,
  });

  final String title;
  final String backgroundAssetPath;
  final String previewCountText;
  final List<String> tags;
  final List<_PackagePriceItem> packages;
  final String? headerPreviewCount;
  final bool showPreviewIcon;
}

class _PackagePriceItem {
  const _PackagePriceItem({
    required this.name,
    required this.price,
    required this.soldCount,
  });

  final String name;
  final String price;
  final int soldCount;
}
