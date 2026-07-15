import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../presentation/attachment_preview_page.dart';

import 'package:europepass/shared/ui/test_style.dart';
class SampleFileSelectionDialog extends StatelessWidget {
  const SampleFileSelectionDialog({
    super.key,
    required this.title,
    required this.itemCount,
    required this.itemBuilder,
    this.itemHeight = 68,
    this.maxListHeight = 320,
  });

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double itemHeight;
  final double maxListHeight;

  @override
  Widget build(BuildContext context) {
    final double dialogWidth = MediaQuery.sizeOf(context).width - 40;
    final double listHeight = itemCount >= 4
        ? maxListHeight
        : itemCount * itemHeight;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: dialogWidth > 360.0 ? 360.0 : dialogWidth,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              textAlign: TextAlign.center,
              style: TestStyle.semibold(fontSize: 16, color: const Color(0xFF262626)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: listHeight,
              child: ListView.builder(
                itemCount: itemCount,
                itemBuilder: itemBuilder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SampleFileSelectionItem extends StatelessWidget {
  const SampleFileSelectionItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fileUrl,
    this.fileType = '',
    required this.isDownloading,
    this.onTap,
    this.onDownloadTap,
  });

  final String title;
  final String subtitle;
  final String fileUrl;
  final String fileType;
  final bool isDownloading;
  final VoidCallback? onTap;
  final VoidCallback? onDownloadTap;

  /// 判断当前样例文件是否为图片，主体区域点击后走图片预览。
  bool get _isImage {
    final String normalizedType = fileType.trim().toLowerCase();
    final String normalizedUrl = fileUrl.trim().toLowerCase();
    return normalizedType.startsWith('image/') ||
        normalizedUrl.endsWith('.png') ||
        normalizedUrl.endsWith('.jpg') ||
        normalizedUrl.endsWith('.jpeg') ||
        normalizedUrl.endsWith('.webp');
  }

  /// 判断当前样例文件是否为 PDF，主体区域点击后走 PDF 预览。
  bool get _isPdf {
    final String normalizedType = fileType.trim().toLowerCase();
    final String normalizedUrl = fileUrl.trim().toLowerCase();
    return normalizedType.contains('pdf') || normalizedUrl.endsWith('.pdf');
  }

  /// 统一处理主体区域点击，复用现有附件预览页承载图片和 PDF 预览。
  Future<void> _handlePreviewTap(BuildContext context) async {
    final String normalizedUrl = fileUrl.trim();
    if (normalizedUrl.isEmpty) {
      return;
    }
    if (_isImage || _isPdf) {
      await openAttachmentPreview(
        context,
        path: normalizedUrl,
        title: title,
        isImage: _isImage,
        isPdf: _isPdf,
      );
    }
  }

  /// 构建样例文件列表项，并将主体预览和下载按钮拆成两个独立热区。
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap ??
                    ((_isImage || _isPdf)
                        ? () {
                            _handlePreviewTap(context);
                          }
                        : null),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: <Widget>[
                      SvgPicture.asset(
                        _isImage
                            ? 'assets/images/order_detail_file_photo.svg'
                            : 'assets/images/order_detail_file_pdf.svg',
                        width: 32,
                        height: 32,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TestStyle.regular(
                                fontSize: 14,
                                color: const Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TestStyle.regular(
                                fontSize: 11,
                                color: const Color(0xFF999999),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onDownloadTap != null) ...<Widget>[
            const SizedBox(width: 8),
            InkWell(
              onTap: isDownloading ? null : onDownloadTap,
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF262626),
                            ),
                          ),
                        )
                      : SvgPicture.asset(
                          'assets/images/order_detail_download.svg',
                          width: 15,
                          height: 15,
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
