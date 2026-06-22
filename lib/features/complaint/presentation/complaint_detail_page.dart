import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../data/complaint_models.dart';
import '../data/complaint_providers.dart';

class ComplaintDetailPageArgs {
  const ComplaintDetailPageArgs({required this.complaintId});

  final int complaintId;
}

class ComplaintDetailPage extends ConsumerWidget {
  const ComplaintDetailPage({super.key, required this.args});

  final ComplaintDetailPageArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ComplaintVO> detailAsync = ref.watch(
      complaintDetailProvider(args.complaintId),
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
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
              return;
            }
            context.go(RoutePaths.myComplaints);
          },
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          '投诉.详情标题'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontWeight: FontWeight.w500,
            fontSize: 17,
          ),
        ),
      ),
      body: detailAsync.when(
        data: (ComplaintVO detail) => _ComplaintDetailBody(detail: detail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace _) {
          final String message = error is ApiException
              ? error.message
              : '投诉.详情加载失败'.tr();
          return _ComplaintErrorState(
            message: message,
            onRetry: () =>
                ref.invalidate(complaintDetailProvider(args.complaintId)),
          );
        },
      ),
    );
  }
}

class _ComplaintDetailBody extends StatelessWidget {
  const _ComplaintDetailBody({required this.detail});

  final ComplaintVO detail;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: <Widget>[
        _SectionCard(
          children: <Widget>[
            _InfoRow(label: '投诉.编号'.tr(), value: '#${detail.complaintId}'),
            _InfoRow(label: '投诉.对象'.tr(), value: detail.targetName),
            _InfoRow(
              label: '投诉.对象类型'.tr(),
              value: _targetTypeLabel(detail.targetType),
            ),
            _InfoRow(label: '投诉.状态'.tr(), value: detail.displayStatusLabel),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          children: <Widget>[
            _BlockTitle(title: '投诉.标题'.tr()),
            const SizedBox(height: 8),
            Text(
              detail.title.trim().isEmpty ? '-' : detail.title.trim(),
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _BlockTitle(title: '投诉.内容'.tr()),
            const SizedBox(height: 8),
            Text(
              detail.content.trim().isEmpty ? '-' : detail.content.trim(),
              style: const TextStyle(
                color: Color(0xFF595959),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          children: <Widget>[
            _BlockTitle(title: '投诉.附件'.tr()),
            const SizedBox(height: 12),
            if (detail.attachmentUrls.isEmpty)
              Text(
                '投诉.暂无附件'.tr(),
                style: TextStyle(color: Color(0xFF8C8C8C), fontSize: 13),
              )
            else
              ...detail.attachmentUrls.map(
                (String url) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AttachmentItem(url: url),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          children: <Widget>[
            _InfoRow(label: '投诉.创建时间'.tr(), value: _formatDate(detail.createdAt)),
            _InfoRow(label: '投诉.更新时间'.tr(), value: _formatDate(detail.updatedAt)),
          ],
        ),
      ],
    );
  }

  String _targetTypeLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'visa_provider':
        return '投诉.对象类型签证服务商'.tr();
      case 'employer':
        return '投诉.对象类型雇主'.tr();
      default:
        return raw.trim().isEmpty ? '-' : raw.trim();
    }
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _BlockTitle extends StatelessWidget {
  const _BlockTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF262626),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF8C8C8C), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '-' : value.trim(),
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentItem extends StatelessWidget {
  const _AttachmentItem({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final bool isImage = _isImageUrl(url);
    return Material(
      color: const Color(0xFFF7F8FA),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openUrl(context),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: isImage
                      ? Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const _AttachmentFallback(),
                        )
                      : const _AttachmentFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _displayName(url),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF262626),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: Color(0xFF8C8C8C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) {
      AppToast.show('投诉.附件链接无效'.tr());
      return;
    }
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      AppToast.show('投诉.附件打开失败'.tr());
    }
  }

  String _displayName(String raw) {
    final Uri? uri = Uri.tryParse(raw);
    final List<String> segments = uri?.pathSegments ?? const <String>[];
    if (segments.isNotEmpty && segments.last.trim().isNotEmpty) {
      return segments.last.trim();
    }
    return raw;
  }

  bool _isImageUrl(String raw) {
    final String normalized = raw.toLowerCase();
    return normalized.endsWith('.png') ||
        normalized.endsWith('.jpg') ||
        normalized.endsWith('.jpeg') ||
        normalized.endsWith('.gif') ||
        normalized.endsWith('.webp');
  }
}

class _AttachmentFallback extends StatelessWidget {
  const _AttachmentFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F0F0),
      alignment: Alignment.center,
      child: const Icon(
        Icons.insert_drive_file_outlined,
        color: Color(0xFF8C8C8C),
      ),
    );
  }
}

class _ComplaintErrorState extends StatelessWidget {
  const _ComplaintErrorState({required this.message, required this.onRetry});

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
              style: const TextStyle(color: Color(0xFF8C8C8C), fontSize: 14),
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
