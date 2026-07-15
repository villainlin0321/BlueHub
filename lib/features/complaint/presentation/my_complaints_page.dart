import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/network/page_result.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../data/complaint_models.dart';
import '../data/complaint_providers.dart';
import 'complaint_detail_page.dart';

import 'package:europepass/shared/ui/test_style.dart';
class MyComplaintsPage extends ConsumerWidget {
  const MyComplaintsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const ComplaintListQuery query = ComplaintListQuery();
    final AsyncValue<PageResult<ComplaintVO>> complaintsAsync = ref.watch(
      myComplaintsProvider(query),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(RoutePaths.me);
          },
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          '投诉.我的投诉'.tr(),
          style: TestStyle.pingFangMedium(fontSize: 17, color: const Color(0xE6000000)),
        ),
      ),
      body: complaintsAsync.when(
        data: (PageResult<ComplaintVO> result) {
          if (result.list.isEmpty) {
            return _EmptyState(
              onRefresh: () => ref.invalidate(myComplaintsProvider(query)),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myComplaintsProvider(query));
              await ref.read(myComplaintsProvider(query).future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: result.list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final ComplaintVO item = result.list[index];
                return _ComplaintListTile(
                  item: item,
                  onTap: () {
                    context.push(
                      RoutePaths.complaintDetail,
                      extra: ComplaintDetailPageArgs(
                        complaintId: item.complaintId,
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) {
          final String message = error is ApiException
              ? error.message
              : '投诉.列表加载失败'.tr();
          return _ErrorState(
            message: message,
            onRetry: () => ref.invalidate(myComplaintsProvider(query)),
          );
        },
      ),
    );
  }
}

class _ComplaintListTile extends StatelessWidget {
  const _ComplaintListTile({required this.item, required this.onTap});

  final ComplaintVO item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.title.trim().isEmpty
                          ? '投诉.未命名投诉'.tr()
                          : item.title.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TestStyle.semibold(fontSize: 15, color: Color(0xFF262626)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _StatusChip(label: item.displayStatusLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.targetName.trim().isEmpty ? '-' : item.targetName.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TestStyle.medium(fontSize: 13, color: Color(0xFF595959)),
              ),
              const SizedBox(height: 6),
              Text(
                item.content.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TestStyle.regular(fontSize: 13, color: Color(0xFF8C8C8C)),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Text(
                    _formatDate(item.createdAt),
                    style: TestStyle.regular(fontSize: 12, color: Color(0xFFBFBFBF)),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFFBFBFBF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TestStyle.medium(fontSize: 11, color: Color(0xFF1677FF)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '投诉.暂无投诉记录'.tr(),
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF8C8C8C)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onRefresh,
              child: Text('通用.刷新'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF8C8C8C)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String raw) {
  final DateTime? parsed = DateTime.tryParse(raw);
  if (parsed == null) {
    return raw.trim().isEmpty ? '-' : raw.trim();
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal());
}
