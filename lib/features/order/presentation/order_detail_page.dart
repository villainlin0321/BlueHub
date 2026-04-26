import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/primary_button.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key});

  static const List<_OrderStep> _steps = <_OrderStep>[
    _OrderStep(label: '提交订单', state: _OrderStepState.completed),
    _OrderStep(label: '支付费用', state: _OrderStepState.completed),
    _OrderStep(label: '上传材料', state: _OrderStepState.current, number: 3),
    _OrderStep(label: '材料审核', state: _OrderStepState.pending, number: 4),
    _OrderStep(label: '使馆递交', state: _OrderStepState.pending, number: 5),
    _OrderStep(label: '签证出签', state: _OrderStepState.pending, number: 6),
  ];

  static const List<_MaterialRequirement> _requirements =
      <_MaterialRequirement>[
        _MaterialRequirement(id: 'passport', title: '护照原件及复印件', required: true),
        _MaterialRequirement(
          id: 'chef_certificate',
          title: '厨师资格证公证件',
          required: true,
        ),
        _MaterialRequirement(id: 'german_certificate', title: '德语语言证明'),
      ];

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ImagePicker _imagePicker = ImagePicker();
  late final Map<String, List<_PickedUploadFile>> _uploadsByRequirement;

  @override
  void initState() {
    super.initState();
    _uploadsByRequirement = <String, List<_PickedUploadFile>>{
      for (final _MaterialRequirement requirement
          in OrderDetailPage._requirements)
        requirement.id: <_PickedUploadFile>[],
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_PickedUploadFile> _filesFor(_MaterialRequirement requirement) {
    return _uploadsByRequirement[requirement.id] ?? const <_PickedUploadFile>[];
  }

  Future<void> _openUploadSheet(_MaterialRequirement requirement) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isDismissible: true,
      enableDrag: true,
      builder: (BuildContext sheetContext) {
        return _UploadTypeBottomSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onCameraTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickFromCamera(requirement);
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickFromGallery(requirement);
          },
          onFileTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickFromFiles(requirement);
          },
        );
      },
    );
  }

  Future<void> _pickFromCamera(_MaterialRequirement requirement) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image == null) {
        return;
      }
      _appendUploadFiles(requirement, <_PickedUploadFile>[
        _buildUploadFile(
          path: image.path,
          sourceType: _UploadSourceType.camera,
          name: image.name,
        ),
      ]);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('打开相机失败，请稍后重试');
    }
  }

  Future<void> _pickFromGallery(_MaterialRequirement requirement) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 90,
      );
      if (images.isEmpty) {
        return;
      }
      _appendUploadFiles(
        requirement,
        images
            .map(
              (XFile image) => _buildUploadFile(
                path: image.path,
                sourceType: _UploadSourceType.gallery,
                name: image.name,
              ),
            )
            .toList(),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('打开相册失败，请稍后重试');
    }
  }

  Future<void> _pickFromFiles(_MaterialRequirement requirement) async {
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
      );
      if (result == null) {
        return;
      }

      final List<_PickedUploadFile> pickedFiles = result.files
          .where((PlatformFile file) => file.path != null)
          .map(
            (PlatformFile file) => _buildUploadFile(
              path: file.path!,
              sourceType: _UploadSourceType.file,
              name: file.name,
              sizeBytes: file.size,
            ),
          )
          .toList();

      if (pickedFiles.isEmpty) {
        _showMessage('未能读取所选文件');
        return;
      }

      _appendUploadFiles(requirement, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('选择文件失败，请稍后重试');
    }
  }

  _PickedUploadFile _buildUploadFile({
    required String path,
    required _UploadSourceType sourceType,
    String? name,
    int? sizeBytes,
  }) {
    final int resolvedSizeBytes = sizeBytes ?? _readFileSize(path);
    final String resolvedName = (name == null || name.isEmpty)
        ? _basename(path)
        : name;
    return _PickedUploadFile(
      id: '${DateTime.now().microsecondsSinceEpoch}_${path.hashCode}',
      name: resolvedName,
      path: path,
      sourceType: sourceType,
      state: _UploadItemState.success,
      isImage: _isImagePath(path),
      sizeLabel: resolvedSizeBytes > 0
          ? _formatFileSize(resolvedSizeBytes)
          : null,
    );
  }

  void _appendUploadFiles(
    _MaterialRequirement requirement,
    List<_PickedUploadFile> files,
  ) {
    if (files.isEmpty) {
      return;
    }
    setState(() {
      _uploadsByRequirement[requirement.id] = <_PickedUploadFile>[
        ..._filesFor(requirement),
        ...files,
      ];
    });
  }

  void _removeUploadFile(
    _MaterialRequirement requirement,
    _PickedUploadFile file,
  ) {
    setState(() {
      _uploadsByRequirement[requirement.id] = _filesFor(
        requirement,
      ).where((item) => item.id != file.id).toList();
    });
  }

  String _basename(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  int _readFileSize(String path) {
    try {
      final File file = File(path);
      if (!file.existsSync()) {
        return 0;
      }
      return file.lengthSync();
    } catch (_) {
      return 0;
    }
  }

  bool _isImagePath(String path) {
    final String normalizedPath = path.toLowerCase();
    return normalizedPath.endsWith('.jpg') ||
        normalizedPath.endsWith('.jpeg') ||
        normalizedPath.endsWith('.png') ||
        normalizedPath.endsWith('.webp') ||
        normalizedPath.endsWith('.gif') ||
        normalizedPath.endsWith('.heic') ||
        normalizedPath.endsWith('.heif');
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) {
      return '0KB';
    }
    if (bytes < 1024 * 1024) {
      final double kb = bytes / 1024;
      return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)}KB';
    }
    final double mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              _showMessage('暂无可返回页面');
            }
          },
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: Text(
          '订单详情',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => _showMessage('联系商家（占位）'),
            child: Text(
              '联系商家',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF262626),
                fontWeight: FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const _OrderProgressStepper(steps: OrderDetailPage._steps),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: _OrderInfoCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: _MaterialUploadCard(
              requirements: OrderDetailPage._requirements,
              uploadsByRequirement: _uploadsByRequirement,
              onPreviewTap: (String title) => _showMessage('$title 查看样例（占位）'),
              onUploadTap: _openUploadSheet,
              onDeleteFile: _removeUploadFile,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
      bottomNavigationBar: _BottomSubmitBar(
        onPressed: () => _showMessage('提交材料（占位）'),
      ),
    );
  }
}

class _OrderProgressStepper extends StatelessWidget {
  const _OrderProgressStepper({required this.steps});

  final List<_OrderStep> steps;

  static const double _stepWidth = 50;
  static const double _stepHeight = 46;
  static const double _indicatorSize = 20;
  static const double _connectorGap = 6;
  static const double _connectorWidth = 9;
  static const double _separatorWidth = 16;
  static const double _trackHeight = 20;

  Color _segmentColor(int segmentIndex) {
    return segmentIndex < 2
        ? const Color(0xFF096DD9)
        : Colors.black.withValues(alpha: 0.15);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: steps.length,
        separatorBuilder: (context, index) {
          return SizedBox(
            width: _separatorWidth,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: _trackHeight,
                child: Center(
                  child: Container(
                    width: _separatorWidth,
                    height: 1,
                    color: _segmentColor(index),
                  ),
                ),
              ),
            ),
          );
        },
        itemBuilder: (context, index) {
          final step = steps[index];
          final showLeftConnector = index > 0;
          final showRightConnector = index < steps.length - 1;

          return SizedBox(
            width: _stepWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: _stepWidth,
                  height: _trackHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: _trackHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: _connectorWidth,
                            child: Center(
                              child: showLeftConnector
                                  ? Container(
                                      width: _connectorWidth,
                                      height: 1,
                                      color: _segmentColor(index - 1),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: _connectorGap),
                          _StepIndicator(step: step),
                          const SizedBox(width: _connectorGap),
                          SizedBox(
                            width: _connectorWidth,
                            child: Center(
                              child: showRightConnector
                                  ? Container(
                                      width: _connectorWidth,
                                      height: 1,
                                      color: _segmentColor(index),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: _stepWidth,
                  height: _stepHeight - _indicatorSize - 8,
                  child: Text(
                    step.label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: step.state == _OrderStepState.pending
                          ? const Color(0xFF8C8C8C)
                          : step.state == _OrderStepState.current
                          ? const Color(0xFF096DD9)
                          : const Color(0xFF262626),
                      fontWeight: step.state == _OrderStepState.current
                          ? FontWeight.w500
                          : FontWeight.w400,
                      fontSize: 11,
                      height: 18 / 11,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final _OrderStep step;

  @override
  Widget build(BuildContext context) {
    switch (step.state) {
      case _OrderStepState.completed:
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF096DD9), width: 1.4),
            color: Colors.white,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            'assets/images/order_detail_step_done.svg',
            width: 10,
            height: 8,
          ),
        );
      case _OrderStepState.current:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF096DD9),
          ),
          alignment: Alignment.center,
          child: Text(
            '${step.number}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
      case _OrderStepState.pending:
        return Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFD9D9D9),
          ),
          alignment: Alignment.center,
          child: Text(
            '${step.number}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        );
    }
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '德国厨师专属工作签证',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: Color(0xFF262626),
            ),
          ),
          SizedBox(height: 12),
          _OrderInfoRow(label: '服务商', value: '中欧出海签证服务有限公司'),
          SizedBox(height: 8),
          _OrderInfoRow(label: '套餐类型', value: '基础套餐'),
          SizedBox(height: 8),
          _OrderInfoRow(label: '套餐价格', value: '¥15,000'),
          SizedBox(height: 8),
          _OrderInfoRow(label: '订单号', value: 'CLSKJ98793120238'),
        ],
      ),
    );
  }
}

class _OrderInfoRow extends StatelessWidget {
  const _OrderInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF8C8C8C),
            fontWeight: FontWeight.w400,
            fontSize: 12,
            height: 18 / 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF8C8C8C),
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: 18 / 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _MaterialUploadCard extends StatelessWidget {
  const _MaterialUploadCard({
    required this.requirements,
    required this.uploadsByRequirement,
    required this.onPreviewTap,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final List<_MaterialRequirement> requirements;
  final Map<String, List<_PickedUploadFile>> uploadsByRequirement;
  final ValueChanged<String> onPreviewTap;
  final ValueChanged<_MaterialRequirement> onUploadTap;
  final void Function(_MaterialRequirement, _PickedUploadFile) onDeleteFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: List<Widget>.generate(requirements.length, (int index) {
          final _MaterialRequirement item = requirements[index];
          final List<_PickedUploadFile> files =
              uploadsByRequirement[item.id] ?? const <_PickedUploadFile>[];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == requirements.length - 1 ? 0 : 20,
            ),
            child: _MaterialUploadItem(
              requirement: item,
              files: files,
              onPreviewTap: () => onPreviewTap(item.title),
              onUploadTap: () => onUploadTap(item),
              onDeleteFile: (_PickedUploadFile file) =>
                  onDeleteFile(item, file),
            ),
          );
        }),
      ),
    );
  }
}

class _MaterialUploadItem extends StatelessWidget {
  const _MaterialUploadItem({
    required this.requirement,
    required this.files,
    required this.onPreviewTap,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final _MaterialRequirement requirement;
  final List<_PickedUploadFile> files;
  final VoidCallback onPreviewTap;
  final VoidCallback onUploadTap;
  final ValueChanged<_PickedUploadFile> onDeleteFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(
                    child: Text(
                      requirement.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF171A1D),
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 22 / 14,
                      ),
                    ),
                  ),
                  if (requirement.required) ...<Widget>[
                    const SizedBox(width: 3),
                    SvgPicture.asset(
                      'assets/images/order_detail_required.svg',
                      width: 6,
                      height: 6,
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onPreviewTap,
              child: Text(
                '查看样例',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF096DD9),
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MaterialUploadContent(
          files: files,
          onAddTap: onUploadTap,
          onDeleteFile: onDeleteFile,
        ),
      ],
    );
  }
}

class _MaterialUploadContent extends StatelessWidget {
  const _MaterialUploadContent({
    required this.files,
    required this.onAddTap,
    required this.onDeleteFile,
  });

  final List<_PickedUploadFile> files;
  final VoidCallback onAddTap;
  final ValueChanged<_PickedUploadFile> onDeleteFile;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return _UploadPlaceholder(onTap: onAddTap);
    }

    return Column(
      children: <Widget>[
        ...List<Widget>.generate(files.length, (int index) {
          final _PickedUploadFile file = files[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UploadFileCard(
              file: file,
              onRemoveTap: () => onDeleteFile(file),
            ),
          );
        }),
        _UploadPlaceholder(onTap: onAddTap),
      ],
    );
  }
}

class _UploadFileCard extends StatelessWidget {
  const _UploadFileCard({required this.file, required this.onRemoveTap});

  final _PickedUploadFile file;
  final VoidCallback onRemoveTap;

  @override
  Widget build(BuildContext context) {
    switch (file.state) {
      case _UploadItemState.uploading:
        return _UploadFileCardFrame(
          child: Row(
            children: <Widget>[
              _UploadFileLeading(file: file),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: file.progress,
                        minHeight: 4,
                        backgroundColor: Colors.white,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF096DD9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case _UploadItemState.success:
        return _UploadFileCardFrame(
          child: Row(
            children: <Widget>[
              _UploadFileLeading(file: file),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (file.sizeLabel != null) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        file.sizeLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF8C8C8C),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 18 / 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _RemoveUploadButton(onTap: onRemoveTap),
            ],
          ),
        );
      case _UploadItemState.failure:
        return _UploadFileCardFrame(
          child: Row(
            children: <Widget>[
              _UploadFileLeading(file: file),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF333333),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      file.errorMessage ?? '上传失败，请删除后重新上传',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFD4380D),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 18 / 12,
                      ),
                    ),
                  ],
                ),
              ),
              _RemoveUploadButton(onTap: onRemoveTap),
            ],
          ),
        );
    }
  }
}

class _UploadFileCardFrame extends StatelessWidget {
  const _UploadFileCardFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

class _UploadFileLeading extends StatelessWidget {
  const _UploadFileLeading({required this.file});

  final _PickedUploadFile file;

  @override
  Widget build(BuildContext context) {
    if (file.isImage && file.state == _UploadItemState.success) {
      final File localFile = File(file.path);
      if (localFile.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            localFile,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) {
              return SvgPicture.asset(
                'assets/images/order_upload_file_photo.svg',
                width: 32,
                height: 32,
              );
            },
          ),
        );
      }
    }

    return SvgPicture.asset(
      file.isImage
          ? 'assets/images/order_upload_file_photo.svg'
          : 'assets/images/order_upload_file_pdf.svg',
      width: 32,
      height: 32,
    );
  }
}

class _RemoveUploadButton extends StatelessWidget {
  const _RemoveUploadButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 20,
        height: 20,
        child: Center(
          child: SvgPicture.asset(
            'assets/images/order_upload_remove.svg',
            width: 14,
            height: 14,
          ),
        ),
      ),
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Opacity(
            opacity: 0.6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SvgPicture.asset(
                  'assets/images/order_upload_add_inline.svg',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '上传文件',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF171A1D),
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    height: 20 / 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UploadTypeBottomSheet extends StatelessWidget {
  const _UploadTypeBottomSheet({
    required this.onClose,
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onFileTap,
  });

  final VoidCallback onClose;
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onFileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 224,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 224,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 52,
                child: Row(
                  children: <Widget>[
                    SizedBox(width: 36),
                    Expanded(
                      child: Center(
                        child: Text(
                          '上传类型',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF171A1D),
                                fontWeight: FontWeight.w400,
                                fontSize: 17,
                                height: 25 / 17,
                              ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/order_upload_sheet_close.svg',
                              width: 14,
                              height: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(36.75, 24, 36.75, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    _UploadTypeAction(
                      label: '拍照上传',
                      iconAssetPath:
                          'assets/images/order_upload_sheet_camera.svg',
                      onTap: onCameraTap,
                    ),
                    _UploadTypeAction(
                      label: '本地相册',
                      iconAssetPath:
                          'assets/images/order_upload_sheet_gallery.svg',
                      onTap: onGalleryTap,
                    ),
                    _UploadTypeAction(
                      label: '本地文件',
                      iconAssetPath:
                          'assets/images/order_upload_sheet_file.svg',
                      onTap: onFileTap,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFF171A1D),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTypeAction extends StatelessWidget {
  const _UploadTypeAction({
    required this.label,
    required this.iconAssetPath,
    required this.onTap,
  });

  final String label;
  final String iconAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAssetPath, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF595959),
                fontWeight: FontWeight.w400,
                fontSize: 13,
                height: 18 / 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSubmitBar extends StatelessWidget {
  const _BottomSubmitBar({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFF0F0F0),
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: Opacity(
            opacity: 0.3,
            child: PrimaryButton(
              label: '提交材料',
              onPressed: onPressed,
              enabled: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStep {
  const _OrderStep({required this.label, required this.state, this.number});

  final String label;
  final _OrderStepState state;
  final int? number;
}

enum _OrderStepState { completed, current, pending }

class _MaterialRequirement {
  const _MaterialRequirement({
    required this.id,
    required this.title,
    this.required = false,
  });

  final String id;
  final String title;
  final bool required;
}

enum _UploadSourceType { camera, gallery, file }

enum _UploadItemState { uploading, success, failure }

class _PickedUploadFile {
  const _PickedUploadFile({
    required this.id,
    required this.name,
    required this.path,
    required this.sourceType,
    required this.state,
    required this.isImage,
    this.sizeLabel,
  });

  final String id;
  final String name;
  final String path;
  final _UploadSourceType sourceType;
  final _UploadItemState state;
  final bool isImage;
  final String? sizeLabel;
  final String? errorMessage = null;
  final double progress = 0.48;
}
