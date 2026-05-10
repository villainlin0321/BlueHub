import 'package:flutter/material.dart';

import 'app_svg_icon.dart';

class VisaServiceCardData {
  const VisaServiceCardData({
    required this.title,
    required this.rating,
    required this.cases,
    required this.tags,
    required this.description,
    required this.packages,
    this.avatarAssetPath,
    this.avatarUrl,
    this.verified = false,
    this.archived = false,
    this.statusText,
  });

  final String title;
  final String? avatarAssetPath;
  final String? avatarUrl;
  final String rating;
  final String cases;
  final List<String> tags;
  final String description;
  final List<VisaServicePackageData> packages;
  final bool verified;
  final bool archived;
  final String? statusText;
}

class VisaServicePackageData {
  const VisaServicePackageData({
    required this.title,
    required this.price,
    this.priceHint,
    this.iconAssetPath,
  });

  final String title;
  final String price;
  final String? priceHint;
  final String? iconAssetPath;
}

class VisaServiceCard extends StatelessWidget {
  const VisaServiceCard({super.key, required this.data, this.onTap});

  final VisaServiceCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget card = Stack(
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _VisaServiceAvatar(
                      assetPath: data.avatarAssetPath,
                      avatarUrl: data.avatarUrl,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
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
                              if (data.verified) ...<Widget>[
                                const SizedBox(width: 8),
                                const _VisaServiceVerifiedBadge(),
                              ],
                              if (data.statusText != null) ...<Widget>[
                                const SizedBox(width: 8),
                                Text(
                                  data.statusText!,
                                  style: const TextStyle(
                                    color: Color(0xFF8C8C8C),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    height: 20 / 14,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: <Widget>[
                                const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Color(0xFFFE5815),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  data.rating,
                                  style: const TextStyle(
                                    color: Color(0xFFFE5815),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 16 / 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  data.cases,
                                  style: const TextStyle(
                                    color: Color(0xFF8C8C8C),
                                    fontSize: 12,
                                    height: 16 / 12,
                                  ),
                                ),
                                ...data.tags
                                    .take(2)
                                    .map(
                                      (tag) => Padding(
                                        padding: const EdgeInsets.only(left: 6),
                                        child: _VisaServiceInlineTag(
                                          label: tag,
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF595959),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 18 / 12,
                  ),
                ),
                if (data.packages.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  ...data.packages.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == data.packages.length - 1 ? 0 : 8,
                      ),
                      child: _VisaServicePackageRow(
                        item: entry.value,
                        muted: data.archived,
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
        if (data.archived)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
      ],
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      ),
    );
  }
}

class _VisaServiceAvatar extends StatelessWidget {
  const _VisaServiceAvatar({this.assetPath, this.avatarUrl});

  final String? assetPath;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F5),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildAvatar(),
    );
  }

  /// 优先展示网络头像，其次回退到本地资源，再回退默认图标。
  Widget _buildAvatar() {
    final String? trimmedUrl = avatarUrl?.trim();
    if (trimmedUrl != null && trimmedUrl.isNotEmpty) {
      return Image.network(
        trimmedUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildAssetFallback(),
      );
    }
    return _buildAssetFallback();
  }

  /// 渲染本地头像资源，资源缺失时回退默认图标。
  Widget _buildAssetFallback() {
    if (assetPath == null) {
      return const Icon(Icons.person_outline, color: Color(0xFF8C8C8C));
    }
    return Image.asset(
      assetPath!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return const Icon(Icons.person_outline, color: Color(0xFF8C8C8C));
      },
    );
  }
}

class _VisaServiceVerifiedBadge extends StatelessWidget {
  const _VisaServiceVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 14,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFFEEFC8), Color(0xFFF6C165)],
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'V',
            style: TextStyle(
              color: Color(0xFF784301),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 10 / 10,
            ),
          ),
          SizedBox(width: 2),
          Text(
            '认证',
            style: TextStyle(
              color: Color(0xFF784301),
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 10 / 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisaServiceInlineTag extends StatelessWidget {
  const _VisaServiceInlineTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF386EF8),
          fontSize: 10,
          fontWeight: FontWeight.w400,
          height: 10 / 10,
        ),
      ),
    );
  }
}

class _VisaServicePackageRow extends StatelessWidget {
  const _VisaServicePackageRow({required this.item, required this.muted});

  final VisaServicePackageData item;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final Color titleColor = muted
        ? const Color(0xFF8C8C8C)
        : const Color(0xFF262626);
    final Color priceColor = muted
        ? const Color(0xFF8C8C8C)
        : const Color(0xFF262626);

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          if (item.iconAssetPath == null)
            Icon(
              Icons.work_outline_rounded,
              size: 16,
              color: const Color(0xFF556EA3).withValues(alpha: 0.4),
            )
          else
            AppSvgIcon(
              assetPath: item.iconAssetPath!,
              fallback: Icons.work_outline_rounded,
              size: 16,
              color: const Color(0xFF556EA3),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 24 / 14,
              ),
            ),
          ),
          if (item.priceHint != null) ...<Widget>[
            Text(
              item.priceHint!,
              style: const TextStyle(
                color: Color(0xFFFE5815),
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 24 / 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            item.price,
            style: TextStyle(
              color: priceColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 24 / 14,
            ),
          ),
        ],
      ),
    );
  }
}
