import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/router/route_paths.dart';
import '../../../features/files/data/file_models.dart';
import '../../../features/files/data/file_providers.dart';
import '../../../features/message/application/chat/chat_page_args.dart';
import '../../shell/application/shell_role_provider.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/network/services/file_service.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../shared/widgets/progress_stepper.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../utils/upload_picker_utils.dart';
import '../data/visa_order_models.dart';
import '../data/visa_order_providers.dart';

class OrderDetailPageArgs {
  const OrderDetailPageArgs({required this.orderId});

  final int orderId;
}

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({
    super.key,
    this.args = const OrderDetailPageArgs(orderId: 0),
  });

  final OrderDetailPageArgs args;

  static final List<_MaterialRequirement> _fallbackRequirements =
      <_MaterialRequirement>[
        _MaterialRequirement(
          id: 'passport',
          title: '订单.护照原件及复印件'.tr(),
          required: true,
        ),
        _MaterialRequirement(
          id: 'chef_certificate',
          title: '订单.厨师资格证公证件'.tr(),
          required: true,
        ),
        _MaterialRequirement(
          id: 'german_certificate',
          title: '订单.德语语言证明'.tr(),
        ),
      ];

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  static const int _uploadMaterialsStepNumber = 3;
  static const int _materialReviewStepNumber = 4;
  static const int _embassySubmittedStepNumber = 5;
  static const int _visaIssuedStepNumber = 6;
  final Map<String, List<PickedUploadFile>> _uploadsByRequirement =
      <String, List<PickedUploadFile>>{};
  final List<PickedUploadFile> _visaDocumentUploads = <PickedUploadFile>[];
  final Set<String> _downloadingMaterialUrls = <String>{};
  VisaOrderVO? _orderDetail;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isProcessingOrder = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadOrderDetail);
  }

  Future<void> _loadOrderDetail() async {
    final int orderId = widget.args.orderId;
    if (orderId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = '订单.缺少订单参数'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final VisaOrderVO detail = await ref
          .read(visaOrderServiceProvider)
          .getOrderDetail(orderId: orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _orderDetail = detail;
        _isLoading = false;
      });
      _syncRequirements(detail.requiredMaterials);
      _syncVisaDocuments(detail.visaDocuments);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _resolveErrorMessage(
          error,
          fallback: '订单.订单详情加载失败'.tr(),
        );
      });
    }
  }

  List<_MaterialRequirement> _buildMaterialRequirements(
    List<RequiredMaterialVO>? requiredMaterials,
  ) {
    final List<RequiredMaterialVO> materials =
        (requiredMaterials ?? const <RequiredMaterialVO>[])
            .where((item) => item.name.trim().isNotEmpty)
            .toList(growable: false);
    if (materials.isEmpty) {
      return OrderDetailPage._fallbackRequirements;
    }
    return List<_MaterialRequirement>.generate(materials.length, (int index) {
      final RequiredMaterialVO item = materials[index];
      return _MaterialRequirement(
        id: 'material_${index + 1}',
        title: item.name,
        required: item.isRequired,
      );
    }, growable: false);
  }

  void _syncRequirements(List<RequiredMaterialVO>? requiredMaterials) {
    if (!mounted) {
      return;
    }
    final List<_MaterialRequirement> requirements = _buildMaterialRequirements(
      requiredMaterials,
    );
    setState(() {
      final Map<String, List<PickedUploadFile>> next =
          <String, List<PickedUploadFile>>{};
      for (final _MaterialRequirement requirement in requirements) {
        next[requirement.id] =
            _uploadsByRequirement[requirement.id] ?? <PickedUploadFile>[];
      }
      _uploadsByRequirement
        ..clear()
        ..addAll(next);
    });
  }

  void _syncVisaDocuments(List<VisaDocVO>? visaDocuments) {
    if (!mounted) {
      return;
    }
    final List<PickedUploadFile> uploads =
        (visaDocuments ?? const <VisaDocVO>[])
            .map(_buildPickedUploadFileFromVisaDocument)
            .toList(growable: false);
    setState(() {
      _visaDocumentUploads
        ..clear()
        ..addAll(uploads);
    });
  }

  PickedUploadFile _buildPickedUploadFileFromVisaDocument(VisaDocVO document) {
    final String normalizedPath = _normalizedPathFromUrl(document.fileUrl);
    final String fileName = document.docName.trim().isNotEmpty
        ? document.docName
        : _displayNameFromUrl(document.fileUrl, fallback: '订单.出证材料'.tr());
    return PickedUploadFile(
      id: 'visa_doc_${document.fileUrl.hashCode}_${document.uploadedAt}',
      name: fileName,
      path: normalizedPath.isEmpty ? document.fileUrl : normalizedPath,
      sourceType: UploadSourceType.file,
      state: UploadItemState.success,
      isImage: UploadPickerUtils.isImagePath(normalizedPath),
      uploadedFileUrl: document.fileUrl,
      progress: 1,
    );
  }

  Map<String, List<PickedUploadFile>> _buildReadonlyUploadsByRequirement({
    required List<_MaterialRequirement> requirements,
    required List<MaterialVO> materials,
  }) {
    final Map<String, List<PickedUploadFile>> uploadsByRequirement =
        <String, List<PickedUploadFile>>{
          for (final _MaterialRequirement requirement in requirements)
            requirement.id: <PickedUploadFile>[],
        };
    final Map<String, _MaterialRequirement> requirementByTitle =
        <String, _MaterialRequirement>{
          for (final _MaterialRequirement requirement in requirements)
            requirement.title.trim(): requirement,
        };

    for (final MaterialVO material in materials) {
      final _MaterialRequirement? requirement =
          requirementByTitle[material.materialName.trim()];
      if (requirement == null) {
        continue;
      }
      uploadsByRequirement[requirement.id]!.add(
        PickedUploadFile(
          id: '${requirement.id}_${material.fileUrl.hashCode}_${material.uploadedAt}',
          name: _materialDisplayName(material),
          path: material.fileUrl,
          sourceType: UploadSourceType.file,
          state: UploadItemState.success,
          isImage: material.fileType.trim().toLowerCase().startsWith('image/'),
          sizeLabel: material.fileSize > 0
              ? UploadPickerUtils.formatFileSize(material.fileSize)
              : null,
        ),
      );
    }

    return uploadsByRequirement;
  }

  String _normalizedPathFromUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }
    return uri.path.isEmpty ? value : uri.path;
  }

  String _displayNameFromUrl(String value, {required String fallback}) {
    final Uri? uri = Uri.tryParse(value);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    final String basename = UploadPickerUtils.basename(value);
    return basename.trim().isEmpty ? fallback : basename;
  }

  List<ProgressStep> _buildProgressSteps(VisaOrderVO? detail) {
    final List<StepVO> steps = detail?.steps ?? const <StepVO>[];
    if (steps.isEmpty) {
      return <ProgressStep>[
        ProgressStep(label: '订单.提交订单'.tr(), state: ProgressStepState.completed),
        ProgressStep(label: '订单.支付费用'.tr(), state: ProgressStepState.completed),
        ProgressStep(
          label: '订单.上传材料'.tr(),
          state: ProgressStepState.current,
          number: 3,
        ),
        ProgressStep(
          label: '订单.材料审核'.tr(),
          state: ProgressStepState.pending,
          number: 4,
        ),
        ProgressStep(
          label: '订单.使馆递交'.tr(),
          state: ProgressStepState.pending,
          number: 5,
        ),
        ProgressStep(
          label: '订单.签证出签'.tr(),
          state: ProgressStepState.pending,
          number: 6,
        ),
      ];
    }
    return steps
        .map((StepVO step) {
          final int currentStep = detail?.currentStep ?? 0;
          final ProgressStepState state;
          if (step.step < currentStep) {
            state = ProgressStepState.completed;
          } else if (step.step == currentStep) {
            state = ProgressStepState.current;
          } else {
            state = ProgressStepState.pending;
          }
          final String label = step.label.trim().isEmpty
              ? '订单.步骤'.tr(
                  namedArgs: <String, String>{'step': step.step.toString()},
                )
              : step.label;
          return ProgressStep(label: label, state: state, number: step.step);
        })
        .toList(growable: false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _handleConsultTap() {
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.商家信息加载中'.tr());
      return;
    }
    if (detail.providerInfo.providerId <= 0) {
      _showMessage('订单.商家信息缺失'.tr());
      return;
    }
    context.push(
      RoutePaths.chat,
      extra: ChatPageArgs(
        targetUserId: detail.providerInfo.providerId,
        targetUserRole: 'visa_provider',
        nickname: detail.providerName.trim().isEmpty
            ? '订单.服务商'.tr()
            : detail.providerName,
        avatarUrl: detail.avatarUrl,
        relatedOrderId: detail.orderId,
        packageName: detail.packageName,
        orderStatus: detail.statusLabel,
      ),
    );
  }

  List<PickedUploadFile> _filesFor(_MaterialRequirement requirement) {
    return _uploadsByRequirement[requirement.id] ?? const <PickedUploadFile>[];
  }

  String _currentStepLabel(VisaOrderVO? detail) {
    if (detail == null) {
      return '';
    }
    for (final StepVO step in detail.steps) {
      if (step.step == detail.currentStep) {
        return step.label.trim();
      }
    }
    return detail.statusLabel.trim();
  }

  bool _isUploadMaterialsStage(VisaOrderVO? detail) {
    final String currentStepLabel = _currentStepLabel(detail);
    final String status = detail?.status.trim().toLowerCase() ?? '';
    return (detail?.currentStep ?? 0) == _uploadMaterialsStepNumber ||
        currentStepLabel.contains('订单.上传材料'.tr()) ||
        status.contains('upload');
  }

  bool _isMaterialReviewStage(VisaOrderVO? detail) {
    final String currentStepLabel = _currentStepLabel(detail);
    final String status = detail?.status.trim().toLowerCase() ?? '';
    return (detail?.currentStep ?? 0) == _materialReviewStepNumber ||
        currentStepLabel.contains('订单.材料审核'.tr()) ||
        status.contains('review');
  }

  bool _isRejectedStatus(VisaOrderVO? detail) {
    return (detail?.status.trim().toLowerCase() ?? '') == 'rejected';
  }

  bool _isEmbassySubmittedStage(VisaOrderVO? detail) {
    final String currentStepLabel = _currentStepLabel(detail);
    final String status = detail?.status.trim().toLowerCase() ?? '';
    return (detail?.currentStep ?? 0) == _embassySubmittedStepNumber ||
        currentStepLabel.contains('订单.使馆递交'.tr()) ||
        status.contains('embassy');
  }

  bool _isVisaIssuedStage(VisaOrderVO? detail) {
    final String currentStepLabel = _currentStepLabel(detail);
    final String status = detail?.status.trim().toLowerCase() ?? '';
    return (detail?.currentStep ?? 0) == _visaIssuedStepNumber ||
        currentStepLabel.contains('订单.签证出签'.tr()) ||
        status.contains('visa_issued') ||
        status.contains('issued');
  }

  bool _shouldShowApplicantMaterialCard(VisaOrderVO? detail) {
    return _isUploadMaterialsStage(detail) ||
        _isMaterialReviewStage(detail) ||
        _isEmbassySubmittedStage(detail) ||
        _isVisaIssuedStage(detail);
  }

  bool _shouldShowProviderMaterialCard(VisaOrderVO? detail) {
    return _isUploadMaterialsStage(detail) ||
        _isMaterialReviewStage(detail) ||
        _isEmbassySubmittedStage(detail) ||
        _isVisaIssuedStage(detail);
  }

  void _noopAction() {}

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

  Future<void> _openVisaDocumentUploadSheet() async {
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
            await _pickVisaDocumentsFromCamera();
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickVisaDocumentsFromGallery();
          },
          onFileTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickVisaDocumentsFromFiles();
          },
        );
      },
    );
  }

  Future<void> _pickFromCamera(_MaterialRequirement requirement) async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromCamera();
      if (pickedFiles.isEmpty) {
        return;
      }
      await _appendUploadFiles(requirement, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('订单.打开相机失败'.tr());
    }
  }

  Future<void> _pickFromGallery(_MaterialRequirement requirement) async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromGallery();
      if (pickedFiles.isEmpty) {
        return;
      }
      await _appendUploadFiles(requirement, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('订单.打开相册失败'.tr());
    }
  }

  Future<void> _pickFromFiles(_MaterialRequirement requirement) async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromFiles();
      if (pickedFiles.isEmpty) {
        _showMessage('订单.未能读取所选文件'.tr());
        return;
      }

      await _appendUploadFiles(requirement, pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('订单.选择文件失败'.tr());
    }
  }

  Future<void> _pickVisaDocumentsFromCamera() async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromCamera();
      if (pickedFiles.isEmpty) {
        return;
      }
      await _appendVisaDocumentFiles(pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('订单.打开相机失败'.tr());
    }
  }

  Future<void> _pickVisaDocumentsFromGallery() async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromGallery();
      if (pickedFiles.isEmpty) {
        return;
      }
      await _appendVisaDocumentFiles(pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('订单.打开相册失败'.tr());
    }
  }

  Future<void> _pickVisaDocumentsFromFiles() async {
    try {
      final List<PickedUploadFile> pickedFiles =
          await UploadPickerUtils.pickFromFiles();
      if (pickedFiles.isEmpty) {
        _showMessage('订单.未能读取所选文件'.tr());
        return;
      }
      await _appendVisaDocumentFiles(pickedFiles);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('订单.选择文件失败'.tr());
    }
  }

  Future<void> _appendUploadFiles(
    _MaterialRequirement requirement,
    List<PickedUploadFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }
    final List<PickedUploadFile> pendingFiles = files
        .map(
          (file) => file.copyWith(
            state: UploadItemState.uploading,
            progress: 0,
            errorMessage: null,
            uploadedFileId: null,
            uploadedFileUrl: null,
          ),
        )
        .toList(growable: false);
    setState(() {
      _uploadsByRequirement[requirement.id] = <PickedUploadFile>[
        ..._filesFor(requirement),
        ...pendingFiles,
      ];
    });
    await _uploadPickedFiles(requirement, pendingFiles);
  }

  Future<void> _appendVisaDocumentFiles(List<PickedUploadFile> files) async {
    if (files.isEmpty) {
      return;
    }
    final List<PickedUploadFile> pendingFiles = files
        .map(
          (file) => file.copyWith(
            state: UploadItemState.uploading,
            progress: 0,
            errorMessage: null,
            uploadedFileId: null,
            uploadedFileUrl: null,
          ),
        )
        .toList(growable: false);
    setState(() {
      _visaDocumentUploads.addAll(pendingFiles);
    });
    await _uploadPickedVisaDocuments(pendingFiles);
  }

  void _removeUploadFile(
    _MaterialRequirement requirement,
    PickedUploadFile file,
  ) {
    setState(() {
      _uploadsByRequirement[requirement.id] = _filesFor(
        requirement,
      ).where((item) => item.id != file.id).toList();
    });
  }

  void _removeVisaDocumentFile(PickedUploadFile file) {
    setState(() {
      _visaDocumentUploads.removeWhere((item) => item.id == file.id);
    });
  }

  void _updateUploadFile(
    _MaterialRequirement requirement,
    String fileId,
    PickedUploadFile Function(PickedUploadFile current) update,
  ) {
    setState(() {
      _uploadsByRequirement[requirement.id] = _filesFor(requirement)
          .map((item) {
            if (item.id != fileId) {
              return item;
            }
            return update(item);
          })
          .toList(growable: false);
    });
  }

  void _updateVisaDocumentFile(
    String fileId,
    PickedUploadFile Function(PickedUploadFile current) update,
  ) {
    setState(() {
      for (int index = 0; index < _visaDocumentUploads.length; index++) {
        final PickedUploadFile item = _visaDocumentUploads[index];
        if (item.id == fileId) {
          _visaDocumentUploads[index] = update(item);
          break;
        }
      }
    });
  }

  Future<void> _uploadPickedFiles(
    _MaterialRequirement requirement,
    List<PickedUploadFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }
    final fileService = ref.read(fileServiceProvider);
    for (final PickedUploadFile file in files) {
      try {
        final uploaded = await fileService.uploadFile(
          path: file.path,
          scene: FileScene.material,
          errorMessage: '订单.材料文件上传失败'.tr(),
          onSendProgress: (int sent, int total) {
            if (!mounted || total <= 0) {
              return;
            }
            final double progress = (sent / total).clamp(0, 1).toDouble();
            _updateUploadFile(
              requirement,
              file.id,
              (current) => current.copyWith(
                state: UploadItemState.uploading,
                progress: progress,
                errorMessage: null,
              ),
            );
          },
        );
        if (!mounted) {
          return;
        }
        _updateUploadFile(
          requirement,
          file.id,
          (current) => current.copyWith(
            state: UploadItemState.success,
            progress: 1,
            errorMessage: null,
            uploadedFileId: uploaded.fileId,
            uploadedFileUrl: uploaded.fileUrl,
          ),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        _updateUploadFile(
          requirement,
          file.id,
          (current) => current.copyWith(
            state: UploadItemState.failure,
            progress: 0,
            errorMessage: _resolveErrorMessage(
              error,
              fallback: '订单.上传失败请重试'.tr(),
            ),
            uploadedFileId: null,
            uploadedFileUrl: null,
          ),
        );
      }
    }
  }

  Future<void> _uploadPickedVisaDocuments(List<PickedUploadFile> files) async {
    if (files.isEmpty) {
      return;
    }
    final fileService = ref.read(fileServiceProvider);
    for (final PickedUploadFile file in files) {
      try {
        final uploaded = await fileService.uploadFile(
          path: file.path,
          scene: FileScene.visaDoc,
          errorMessage: '订单.出证材料上传失败'.tr(),
          onSendProgress: (int sent, int total) {
            if (!mounted || total <= 0) {
              return;
            }
            final double progress = (sent / total).clamp(0, 1).toDouble();
            _updateVisaDocumentFile(
              file.id,
              (current) => current.copyWith(
                state: UploadItemState.uploading,
                progress: progress,
                errorMessage: null,
              ),
            );
          },
        );
        if (!mounted) {
          return;
        }
        _updateVisaDocumentFile(
          file.id,
          (current) => current.copyWith(
            state: UploadItemState.success,
            progress: 1,
            errorMessage: null,
            uploadedFileId: uploaded.fileId,
            uploadedFileUrl: uploaded.fileUrl,
          ),
        );
      } catch (error) {
        if (!mounted) {
          return;
        }
        _updateVisaDocumentFile(
          file.id,
          (current) => current.copyWith(
            state: UploadItemState.failure,
            progress: 0,
            errorMessage: _resolveErrorMessage(
              error,
              fallback: '订单.上传失败请重试'.tr(),
            ),
            uploadedFileId: null,
            uploadedFileUrl: null,
          ),
        );
      }
    }
  }

  Future<void> _submitMaterials() async {
    if (_isSubmitting) {
      return;
    }
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.订单详情尚未加载完成'.tr());
      return;
    }
    final List<_MaterialRequirement> requirements = _buildMaterialRequirements(
      detail.requiredMaterials,
    );
    _MaterialRequirement? missingRequirement;
    _MaterialRequirement? failedRequirement;
    for (final _MaterialRequirement item in requirements) {
      if (item.required && _filesFor(item).isEmpty) {
        missingRequirement = item;
        break;
      }
      if (_filesFor(
        item,
      ).any((file) => file.state != UploadItemState.success)) {
        failedRequirement = item;
        break;
      }
    }
    if (missingRequirement != null) {
      _showMessage(
        '订单.请先上传'.tr(namedArgs: <String, String>{'title': missingRequirement.title}),
      );
      return;
    }
    if (failedRequirement != null) {
      _showMessage(
        '订单.存在未上传成功文件'.tr(
          namedArgs: <String, String>{'title': failedRequirement.title},
        ),
      );
      return;
    }

    final int totalFiles = requirements.fold<int>(
      0,
      (count, item) => count + _filesFor(item).length,
    );
    if (totalFiles <= 0) {
      _showMessage('订单.请先选择要提交的材料'.tr());
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final List<MaterialItemBO> requestMaterials = <MaterialItemBO>[];
      for (final _MaterialRequirement requirement in requirements) {
        for (final PickedUploadFile file in _filesFor(requirement)) {
          final int? uploadedFileId = file.uploadedFileId;
          final String uploadedFileUrl = (file.uploadedFileUrl ?? '').trim();
          if (file.state != UploadItemState.success ||
              uploadedFileId == null ||
              uploadedFileUrl.isEmpty) {
            throw ApiException.unknown('订单.存在未上传完成的材料文件'.tr());
          }
          final int fileSize = UploadPickerUtils.readFileSize(file.path);
          requestMaterials.add(
            MaterialItemBO(
              materialName: requirement.title,
              fileId: uploadedFileId,
              fileUrl: uploadedFileUrl,
              fileType: FileService.resolveMimeType(file.path),
              fileSize: fileSize,
            ),
          );
        }
      }

      await ref
          .read(visaOrderServiceProvider)
          .uploadMaterials(
            orderId: detail.orderId,
            request: UploadOrderMaterialsBO(materials: requestMaterials),
          );
      if (!mounted) {
        return;
      }
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showMessage(
        _resolveErrorMessage(error, fallback: '订单.提交材料失败'.tr()),
      );
    }
  }

  Future<void> _completeOrderWithVisaDocuments() async {
    if (_isSubmitting || _isProcessingOrder) {
      return;
    }
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.订单详情尚未加载完成'.tr());
      return;
    }
    if (_visaDocumentUploads.isEmpty) {
      _showMessage('订单.请先上传出证材料'.tr());
      return;
    }
    if (_visaDocumentUploads.any(
      (file) => file.state != UploadItemState.success,
    )) {
      _showMessage('订单.存在未上传成功的出证材料'.tr());
      return;
    }

    final List<DocumentItemBO> newDocuments = _visaDocumentUploads
        .where(
          (file) =>
              file.uploadedFileId != null &&
              (file.uploadedFileUrl ?? '').trim().isNotEmpty,
        )
        .map(
          (file) => DocumentItemBO(
            docName: file.name,
            fileId: file.uploadedFileId!,
            fileUrl: file.uploadedFileUrl!.trim(),
            fileType: FileService.resolveMimeType(file.path),
          ),
        )
        .toList(growable: false);

    setState(() {
      _isSubmitting = true;
      _isProcessingOrder = true;
    });
    try {
      if (newDocuments.isNotEmpty) {
        await ref
            .read(visaOrderServiceProvider)
            .uploadVisaDocuments(
              orderId: detail.orderId,
              request: UploadVisaDocumentsBO(documents: newDocuments),
            );
      }
      if (!mounted) {
        return;
      }
      context.pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        _resolveErrorMessage(error, fallback: '订单.上传出证材料失败'.tr()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isProcessingOrder = false;
        });
      }
    }
  }

  String _resolveErrorMessage(Object error, {required String fallback}) {
    if (error is ApiException) {
      return error.message;
    }
    final String message = error.toString().trim();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message.isEmpty ? fallback : message;
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final List<Directory> candidates = <Directory>[];
    try {
      final Directory? downloadsDirectory = await getDownloadsDirectory();
      if (downloadsDirectory != null) {
        candidates.add(Directory('${downloadsDirectory.path}/BlueHub'));
      }
    } catch (_) {}

    try {
      final Directory documentsDirectory =
          await getApplicationDocumentsDirectory();
      candidates.add(Directory('${documentsDirectory.path}/downloads'));
    } catch (_) {}

    final Directory temporaryDirectory = await getTemporaryDirectory();
    candidates.add(Directory('${temporaryDirectory.path}/downloads'));

    for (final Directory candidate in candidates) {
      if (await _canWriteToDirectory(candidate)) {
        return candidate;
      }
    }
    throw Exception('订单.下载目录无访问权限'.tr());
  }

  Future<bool> _canWriteToDirectory(Directory directory) async {
    try {
      if (!directory.existsSync()) {
        await directory.create(recursive: true);
      }
      final File probeFile = File(
        '${directory.path}/.bluehub_write_test_${DateTime.now().microsecondsSinceEpoch}',
      );
      await probeFile.writeAsString('ok', flush: true);
      if (probeFile.existsSync()) {
        await probeFile.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  String _materialDisplayName(MaterialVO material) {
    final String materialName = material.materialName.trim();
    if (materialName.isNotEmpty) {
      return materialName;
    }
    final Uri? uri = Uri.tryParse(material.fileUrl);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return '订单.订单材料'.tr();
  }

  String _materialFileExtension(MaterialVO material) {
    final String name = _materialDisplayName(material);
    final int dotIndex = name.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < name.length - 1) {
      return name.substring(dotIndex);
    }

    final Uri? uri = Uri.tryParse(material.fileUrl);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final String lastSegment = Uri.decodeComponent(uri.pathSegments.last);
      final int urlDotIndex = lastSegment.lastIndexOf('.');
      if (urlDotIndex >= 0 && urlDotIndex < lastSegment.length - 1) {
        return lastSegment.substring(urlDotIndex);
      }
    }

    final String type = material.fileType.trim().toLowerCase();
    if (type.contains('png')) {
      return '.png';
    }
    if (type.contains('jpeg') || type.contains('jpg')) {
      return '.jpg';
    }
    if (type.contains('pdf')) {
      return '.pdf';
    }
    return '';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  Future<void> _downloadMaterial(MaterialVO material) async {
    final String fileUrl = material.fileUrl.trim();
    if (fileUrl.isEmpty) {
      _showMessage('订单.文件地址不存在'.tr());
      return;
    }
    if (_downloadingMaterialUrls.contains(fileUrl)) {
      return;
    }

    setState(() {
      _downloadingMaterialUrls.add(fileUrl);
    });

    final Dio dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    try {
      final Directory directory = await _resolveDownloadDirectory();
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final String displayName = _materialDisplayName(material);
      final String extension = _materialFileExtension(material);
      final String normalizedName =
          displayName.contains('.') || extension.isEmpty
          ? displayName
          : '$displayName$extension';
      final String sanitizedName = _sanitizeFileName(normalizedName);
      String savePath = '${directory.path}/$sanitizedName';
      if (File(savePath).existsSync()) {
        final String timestamp = DateTime.now().millisecondsSinceEpoch
            .toString();
        final int nameDotIndex = sanitizedName.lastIndexOf('.');
        final String uniqueName = nameDotIndex > 0
            ? '${sanitizedName.substring(0, nameDotIndex)}_$timestamp${sanitizedName.substring(nameDotIndex)}'
            : '${sanitizedName}_$timestamp';
        savePath = '${directory.path}/$uniqueName';
      }

      await dio.download(
        fileUrl,
        savePath,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
        deleteOnError: true,
      );

      if (!mounted) {
        return;
      }
      _showMessage('${'订单.已下载到本地'.tr()}\n$savePath');
    } on DioException {
      if (!mounted) {
        return;
      }
      _showMessage('订单.文件下载失败'.tr());
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error, fallback: '订单.文件下载失败'.tr()));
    } finally {
      dio.close(force: true);
      if (mounted) {
        setState(() {
          _downloadingMaterialUrls.remove(fileUrl);
        });
      }
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext sheetContext) {
        return _RejectReasonBottomSheet(
          initialReason: (_orderDetail?.rejectReason ?? '').trim(),
          onClose: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  Future<void> _processOrder({
    required String action,
    required String nextStatus,
    required String remark,
  }) async {
    if (_isProcessingOrder) {
      return;
    }
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.订单详情尚未加载完成'.tr());
      return;
    }

    setState(() => _isProcessingOrder = true);
    try {
      await ref
          .read(visaOrderServiceProvider)
          .processOrder(
            orderId: detail.orderId,
            request: ProcessOrderBO(
              action: action,
              remark: remark,
              nextStatus: nextStatus,
            ),
          );
      if (!mounted) {
        return;
      }
      if (context.canPop()) {
        context.pop(true);
        return;
      }
      await _loadOrderDetail();
      if (!mounted) {
        return;
      }
      _showMessage(
        action == 'approve' ? '订单.审核已通过'.tr() : '订单.已驳回重传'.tr(),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error, fallback: '订单.订单处理失败'.tr()));
    } finally {
      if (mounted) {
        setState(() => _isProcessingOrder = false);
      }
    }
  }

  Future<void> _handleApproveOrder() async {
    await _processOrder(
      action: 'approve',
      nextStatus: 'embassy_submitted',
      remark: '',
    );
  }

  Future<void> _handleRejectOrder() async {
    final String? reason = await _showRejectReasonDialog();
    if (reason == null || reason.trim().isEmpty) {
      return;
    }
    await _processOrder(
      action: 'reject',
      nextStatus: '',
      remark: reason.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ShellRole currentRole = ref.watch(shellRoleProvider);
    final bool isServiceProvider = currentRole == ShellRole.serviceProvider;
    final VisaOrderVO? detail = _orderDetail;
    final List<_MaterialRequirement> requirements = _buildMaterialRequirements(
      detail?.requiredMaterials,
    );
    final bool isUploadMaterialsStage = _isUploadMaterialsStage(detail);
    final bool isMaterialReviewStage = _isMaterialReviewStage(detail);
    final bool isEmbassySubmittedStage = _isEmbassySubmittedStage(detail);
    final bool isVisaIssuedStage = _isVisaIssuedStage(detail);
    final bool shouldShowApplicantMaterialCard =
        _shouldShowApplicantMaterialCard(detail);
    final bool shouldShowProviderMaterialCard = _shouldShowProviderMaterialCard(
      detail,
    );
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
              _showMessage('订单.暂无可返回页面'.tr());
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
          '订单.订单详情'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xE6000000),
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: isServiceProvider
            ? const <Widget>[]
            : <Widget>[
                TextButton(
                  onPressed: _handleConsultTap,
                  child: Text(
                    '订单.联系商家'.tr(),
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
      body: _buildBody(
        detail: detail,
        requirements: requirements,
        isServiceProvider: isServiceProvider,
        isUploadMaterialsStage: isUploadMaterialsStage,
        isMaterialReviewStage: isMaterialReviewStage,
        isEmbassySubmittedStage: isEmbassySubmittedStage,
        isVisaIssuedStage: isVisaIssuedStage,
        shouldShowApplicantMaterialCard: shouldShowApplicantMaterialCard,
        shouldShowProviderMaterialCard: shouldShowProviderMaterialCard,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(
        detail: detail,
        isServiceProvider: isServiceProvider,
        isUploadMaterialsStage: isUploadMaterialsStage,
        isMaterialReviewStage: isMaterialReviewStage,
        isEmbassySubmittedStage: isEmbassySubmittedStage,
      ),
    );
  }

  Widget _buildBottomNavigationBar({
    required VisaOrderVO? detail,
    required bool isServiceProvider,
    required bool isUploadMaterialsStage,
    required bool isMaterialReviewStage,
    required bool isEmbassySubmittedStage,
  }) {
    if (detail == null) {
      return const SizedBox.shrink();
    }
    if (_isRejectedStatus(detail)) {
      return const _RejectedStatusBar();
    }
    if (isUploadMaterialsStage) {
      if (isServiceProvider) {
        return const SizedBox.shrink();
      }
      return _BottomSubmitBar(
        label: _isSubmitting ? '订单.提交材料中'.tr() : '订单.提交材料'.tr(),
        enabled: !_isLoading && _errorMessage == null && !_isSubmitting,
        onPressed: _submitMaterials,
      );
    }
    if (isMaterialReviewStage) {
      if (isServiceProvider) {
        return _ProviderBottomActionBar(
          enabled:
              !_isLoading &&
              _errorMessage == null &&
              !_isSubmitting &&
              !_isProcessingOrder,
          onRejectTap: _handleRejectOrder,
          onApproveTap: _handleApproveOrder,
        );
      }
      return _BottomSubmitBar(
        label: '订单.材料审核中'.tr(),
        enabled: false,
        onPressed: _noopAction,
      );
    }
    if (isEmbassySubmittedStage && isServiceProvider) {
      return _BottomSubmitBar(
        label: _isSubmitting || _isProcessingOrder
            ? '订单.完结中'.tr()
            : '订单.完结'.tr(),
        enabled:
            !_isLoading &&
            _errorMessage == null &&
            !_isSubmitting &&
            !_isProcessingOrder,
        onPressed: _completeOrderWithVisaDocuments,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBody({
    required VisaOrderVO? detail,
    required List<_MaterialRequirement> requirements,
    required bool isServiceProvider,
    required bool isUploadMaterialsStage,
    required bool isMaterialReviewStage,
    required bool isEmbassySubmittedStage,
    required bool isVisaIssuedStage,
    required bool shouldShowApplicantMaterialCard,
    required bool shouldShowProviderMaterialCard,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _OrderDetailStateView(
        message: _errorMessage!,
        buttonLabel: '通用.重试'.tr(),
        onTap: _loadOrderDetail,
      );
    }
    if (detail == null) {
      return _OrderDetailStateView(
        message: '订单.订单详情不存在'.tr(),
        buttonLabel: '订单.返回'.tr(),
        onTap: () => context.pop(),
      );
    }
    final Map<String, List<PickedUploadFile>> displayedUploadsByRequirement =
        isUploadMaterialsStage
        ? _uploadsByRequirement
        : _buildReadonlyUploadsByRequirement(
            requirements: requirements,
            materials: detail.materials,
          );
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _OrderProgressStepper(steps: _buildProgressSteps(detail)),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: _OrderInfoCard(order: detail),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: isServiceProvider
              ? shouldShowProviderMaterialCard
                    ? _ProviderMaterialReviewCard(
                        materials: detail.materials,
                        downloadingFileUrls: _downloadingMaterialUrls,
                        onDownloadTap: _downloadMaterial,
                      )
                    : const SizedBox.shrink()
              : shouldShowApplicantMaterialCard
              ? _MaterialUploadCard(
                  requirements: requirements,
                  uploadsByRequirement: displayedUploadsByRequirement,
                  allowUpload: isUploadMaterialsStage,
                  allowDelete: isUploadMaterialsStage,
                  onPreviewTap: (String title) =>
                      _showMessage(
                        '订单.查看样例占位'.tr(
                          namedArgs: <String, String>{'title': title},
                        ),
                      ),
                  onUploadTap: _openUploadSheet,
                  onDeleteFile: _removeUploadFile,
                )
              : const SizedBox.shrink(),
        ),
        if (isServiceProvider && (isEmbassySubmittedStage || isVisaIssuedStage))
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _ProviderVisaDocumentUploadCard(
              files: _visaDocumentUploads,
              allowUpload: isEmbassySubmittedStage,
              allowDelete: isEmbassySubmittedStage,
              onUploadTap: _openVisaDocumentUploadSheet,
              onDeleteFile: _removeVisaDocumentFile,
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _OrderProgressStepper extends StatelessWidget {
  const _OrderProgressStepper({required this.steps});

  final List<ProgressStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ProgressStepper(steps: steps),
    );
  }
}

class _OrderInfoCard extends StatelessWidget {
  const _OrderInfoCard({required this.order});

  final VisaOrderVO order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            order.packageName.trim().isEmpty
                ? '订单.未命名订单'.tr()
                : order.packageName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 20 / 14,
              color: Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 12),
          _OrderInfoRow(label: '订单.服务商'.tr(), value: order.providerName),
          const SizedBox(height: 8),
          _OrderInfoRow(label: '服务详情.套餐类型'.tr(), value: order.tierName),
          const SizedBox(height: 8),
          _OrderInfoRow(
            label: '订单.套餐价格'.tr(),
            value: _formatAmount(order.amount),
          ),
          const SizedBox(height: 8),
          _OrderInfoRow(label: '订单.订单号'.tr(), value: order.orderNo),
        ],
      ),
    );
  }

  static String _formatAmount(double amount) {
    final String value = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(2);
    return '¥$value';
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
    required this.allowUpload,
    required this.allowDelete,
    required this.onPreviewTap,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final List<_MaterialRequirement> requirements;
  final Map<String, List<PickedUploadFile>> uploadsByRequirement;
  final bool allowUpload;
  final bool allowDelete;
  final ValueChanged<String> onPreviewTap;
  final ValueChanged<_MaterialRequirement> onUploadTap;
  final void Function(_MaterialRequirement, PickedUploadFile) onDeleteFile;

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
          final List<PickedUploadFile> files =
              uploadsByRequirement[item.id] ?? const <PickedUploadFile>[];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == requirements.length - 1 ? 0 : 20,
            ),
            child: _MaterialUploadItem(
              requirement: item,
              files: files,
              allowUpload: allowUpload,
              allowDelete: allowDelete,
              onPreviewTap: () => onPreviewTap(item.title),
              onUploadTap: allowUpload ? () => onUploadTap(item) : null,
              onDeleteFile: allowDelete
                  ? (PickedUploadFile file) => onDeleteFile(item, file)
                  : null,
            ),
          );
        }),
      ),
    );
  }
}

class _ProviderVisaDocumentUploadCard extends StatelessWidget {
  const _ProviderVisaDocumentUploadCard({
    required this.files,
    required this.allowUpload,
    required this.allowDelete,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final List<PickedUploadFile> files;
  final bool allowUpload;
  final bool allowDelete;
  final VoidCallback onUploadTap;
  final ValueChanged<PickedUploadFile> onDeleteFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '订单.添加出证材料'.tr(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF171A1D),
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 22 / 14,
            ),
          ),
          const SizedBox(height: 12),
          _MaterialUploadContent(
            files: files,
            allowUpload: allowUpload,
            allowDelete: allowDelete,
            onAddTap: onUploadTap,
            onDeleteFile: onDeleteFile,
          ),
        ],
      ),
    );
  }
}

class _ProviderMaterialReviewCard extends StatelessWidget {
  const _ProviderMaterialReviewCard({
    required this.materials,
    required this.downloadingFileUrls,
    this.onDownloadTap,
  });

  final List<MaterialVO> materials;
  final Set<String> downloadingFileUrls;
  final Future<void> Function(MaterialVO)? onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '订单.客户上传材料'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF262626),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 22 / 16,
                  ),
                ),
              ),
              Text(
                '订单.共份'.tr(
                  namedArgs: <String, String>{'count': materials.length.toString()},
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF8C8C8C),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (materials.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: AppEmptyState(
                message: '订单.暂无客户上传材料'.tr(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            )
          else
            ...List<Widget>.generate(materials.length, (int index) {
              final MaterialVO material = materials[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == materials.length - 1 ? 0 : 12,
                ),
                child: _ProviderMaterialFileCard(
                  material: material,
                  isDownloading: downloadingFileUrls.contains(
                    material.fileUrl.trim(),
                  ),
                  onDownloadTap: onDownloadTap == null
                      ? null
                      : () => onDownloadTap!(material),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ProviderMaterialFileCard extends StatelessWidget {
  const _ProviderMaterialFileCard({
    required this.material,
    required this.isDownloading,
    this.onDownloadTap,
  });

  final MaterialVO material;
  final bool isDownloading;
  final VoidCallback? onDownloadTap;

  bool get _isImage {
    final String type = material.fileType.trim().toLowerCase();
    final String url = material.fileUrl.trim().toLowerCase();
    return type.startsWith('image/') ||
        url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.webp');
  }

  String get _displayName {
    final String name = material.materialName.trim();
    if (name.isNotEmpty) {
      return name;
    }
    final Uri? uri = Uri.tryParse(material.fileUrl);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return '订单.订单材料'.tr();
  }

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
                  _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF333333),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  UploadPickerUtils.formatFileSize(material.fileSize),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF999999),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    height: 14 / 11,
                  ),
                ),
              ],
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

class _MaterialUploadItem extends StatelessWidget {
  const _MaterialUploadItem({
    required this.requirement,
    required this.files,
    required this.allowUpload,
    required this.allowDelete,
    required this.onPreviewTap,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final _MaterialRequirement requirement;
  final List<PickedUploadFile> files;
  final bool allowUpload;
  final bool allowDelete;
  final VoidCallback onPreviewTap;
  final VoidCallback? onUploadTap;
  final ValueChanged<PickedUploadFile>? onDeleteFile;

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
                '服务详情.查看样例'.tr(),
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
          allowUpload: allowUpload,
          allowDelete: allowDelete,
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
    required this.allowUpload,
    required this.allowDelete,
    required this.onAddTap,
    required this.onDeleteFile,
  });

  final List<PickedUploadFile> files;
  final bool allowUpload;
  final bool allowDelete;
  final VoidCallback? onAddTap;
  final ValueChanged<PickedUploadFile>? onDeleteFile;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      if (allowUpload && onAddTap != null) {
        return _UploadPlaceholder(onTap: onAddTap!);
      }
      return _ReadonlyUploadPlaceholder(text: '订单.待求职者上传材料'.tr());
    }

    return Column(
      children: <Widget>[
        ...List<Widget>.generate(files.length, (int index) {
          final PickedUploadFile file = files[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UploadFileCard(
              file: file,
              showRemoveButton: allowDelete && onDeleteFile != null,
              onRemoveTap: onDeleteFile == null
                  ? null
                  : () => onDeleteFile!(file),
            ),
          );
        }),
        if (allowUpload && onAddTap != null)
          _UploadPlaceholder(onTap: onAddTap!),
      ],
    );
  }
}

class _UploadFileCard extends StatelessWidget {
  const _UploadFileCard({
    required this.file,
    this.onRemoveTap,
    this.showRemoveButton = true,
  });

  final PickedUploadFile file;
  final VoidCallback? onRemoveTap;
  final bool showRemoveButton;

  @override
  Widget build(BuildContext context) {
    switch (file.state) {
      case UploadItemState.uploading:
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
      case UploadItemState.success:
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
              if (showRemoveButton && onRemoveTap != null)
                _RemoveUploadButton(onTap: onRemoveTap!),
            ],
          ),
        );
      case UploadItemState.failure:
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
                        color: const Color(0xFFD4380D),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (file.errorMessage ?? '订单.上传失败请重试'.tr()).trim(),
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
              if (showRemoveButton && onRemoveTap != null)
                _RemoveUploadButton(onTap: onRemoveTap!),
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
      constraints: const BoxConstraints(minHeight: 56),
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

  final PickedUploadFile file;

  @override
  Widget build(BuildContext context) {
    final String filePath = file.path.toLowerCase();
    final String fileName = file.name.toLowerCase();
    final bool isPdfFile =
        filePath.endsWith('.pdf') || fileName.endsWith('.pdf');

    return Image.asset(
      isPdfFile ? 'assets/images/icon_pdf.png' : 'assets/images/icon_file.png',
      width: 32,
      height: 32,
      fit: BoxFit.cover,
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
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFF707788),
          borderRadius: BorderRadius.circular(10),
        ),
        child: SvgPicture.asset(
          'assets/images/order_upload_remove.svg',
          width: 8,
          height: 8,
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
                  '订单.上传文件'.tr(),
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

class _ReadonlyUploadPlaceholder extends StatelessWidget {
  const _ReadonlyUploadPlaceholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF8C8C8C),
          fontWeight: FontWeight.w400,
          fontSize: 14,
          height: 20 / 14,
        ),
      ),
    );
  }
}

class _RejectReasonBottomSheet extends StatefulWidget {
  const _RejectReasonBottomSheet({
    required this.initialReason,
    required this.onClose,
  });

  final String initialReason;
  final VoidCallback onClose;

  @override
  State<_RejectReasonBottomSheet> createState() =>
      _RejectReasonBottomSheetState();
}

class _RejectReasonBottomSheetState extends State<_RejectReasonBottomSheet> {
  static const int _maxReasonLength = 50;

  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _truncateReason(widget.initialReason.trim()),
    )..addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleTextChanged)
      ..dispose();
    super.dispose();
  }

  String _truncateReason(String value) {
    if (value.length <= _maxReasonLength) {
      return value;
    }
    return value.substring(0, _maxReasonLength);
  }

  void _handleTextChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      if (_errorText != null && _controller.text.trim().isNotEmpty) {
        _errorText = null;
      }
    });
  }

  void _handleConfirm() {
    final String reason = _controller.text.trim();
    if (reason.isEmpty) {
      setState(() => _errorText = '订单.请输入驳回原因'.tr());
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final double topSafeArea = MediaQuery.paddingOf(context).top;
    final int currentLength = _controller.text.length;

    return TapBlankToDismissKeyboard(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(top: topSafeArea + 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF6F6F6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(
                      height: 52,
                      child: Stack(
                        children: <Widget>[
                          Align(
                            child: Text(
                              '订单.驳回材料'.tr(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF171A1D),
                                fontSize: 17,
                                height: 25 / 17,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: InkWell(
                              onTap: widget.onClose,
                              borderRadius: BorderRadius.circular(10),
                              child: const SizedBox(
                                width: 20,
                                height: 20,
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: Color(0xFF171A1D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Text(
                        '订单.驳回说明'.tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF595959),
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _RejectReasonInputCard(
                        controller: _controller,
                        errorText: _errorText,
                        currentLength: currentLength,
                        maxLength: _maxReasonLength,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFF0F0F0)),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            12,
                            12,
                            12,
                            12 + bottomSafeArea,
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _RejectReasonActionButton(
                                  label: '通用.取消'.tr(),
                                  backgroundColor: const Color(0xFFF0F0F0),
                                  foregroundColor: const Color(0xFF262626),
                                  onTap: widget.onClose,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RejectReasonActionButton(
                                  label: '订单.确认驳回'.tr(),
                                  backgroundColor: const Color(0xFFD9363E),
                                  foregroundColor: Colors.white,
                                  onTap: _handleConfirm,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RejectReasonInputCard extends StatelessWidget {
  const _RejectReasonInputCard({
    required this.controller,
    required this.errorText,
    required this.currentLength,
    required this.maxLength,
  });

  final TextEditingController controller;
  final String? errorText;
  final int currentLength;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: hasError
                ? Border.all(color: const Color(0xFFD9363E))
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Column(
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                minLines: 4,
                maxLines: 4,
                maxLength: maxLength,
                inputFormatters: <TextInputFormatter>[
                  LengthLimitingTextInputFormatter(maxLength),
                ],
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF262626),
                  fontSize: 14,
                  height: 24 / 14,
                  fontWeight: FontWeight.w400,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  counterText: '',
                  hintText: '订单.驳回原因示例'.tr(),
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8C8C8C),
                    fontSize: 14,
                    height: 24 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$currentLength/$maxLength',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFBFBFBF),
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFD9363E),
              fontSize: 12,
              height: 18 / 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}

class _RejectReasonActionButton extends StatelessWidget {
  const _RejectReasonActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: foregroundColor,
            fontSize: 16,
            height: 22 / 16,
            fontWeight: FontWeight.w400,
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
                          '订单.上传类型'.tr(),
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
                      label: '订单.拍照上传'.tr(),
                      iconAssetPath:
                          'assets/images/order_upload_sheet_camera.svg',
                      onTap: onCameraTap,
                    ),
                    _UploadTypeAction(
                      label: '订单.本地相册'.tr(),
                      iconAssetPath:
                          'assets/images/order_upload_sheet_gallery.svg',
                      onTap: onGalleryTap,
                    ),
                    _UploadTypeAction(
                      label: '订单.本地文件'.tr(),
                      iconAssetPath:
                          'assets/images/order_upload_sheet_file.svg',
                      onTap: onFileTap,
                    ),
                  ],
                ),
              ),
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

class _OrderDetailStateView extends StatelessWidget {
  const _OrderDetailStateView({
    required this.message,
    required this.buttonLabel,
    required this.onTap,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onTap;

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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF595959),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: buttonLabel, onPressed: onTap, enabled: true),
          ],
        ),
      ),
    );
  }
}

class _BottomSubmitBar extends StatelessWidget {
  const _BottomSubmitBar({
    required this.label,
    required this.onPressed,
    required this.enabled,
  });

  final String label;
  final VoidCallback onPressed;
  final bool enabled;

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
            opacity: enabled ? 1 : 0.4,
            child: PrimaryButton(
              label: label,
              onPressed: enabled ? onPressed : () {},
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
  }
}

class _RejectedStatusBar extends StatelessWidget {
  const _RejectedStatusBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFFF0F0F0),
                offset: const Offset(0, -0.5),
              ),
            ],
          ),
          child: Container(
            height: 44,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD9D9D9)),
            ),
            alignment: Alignment.center,
            child: Text(
              '订单.已驳回'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF8C8C8C),
                fontSize: 16,
                height: 22 / 16,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderBottomActionBar extends StatelessWidget {
  const _ProviderBottomActionBar({
    required this.enabled,
    required this.onRejectTap,
    required this.onApproveTap,
  });

  final bool enabled;
  final VoidCallback onRejectTap;
  final VoidCallback onApproveTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
            opacity: enabled ? 1 : 0.4,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: enabled ? onRejectTap : null,
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFFFEBEB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '订单.驳回重传'.tr(),
                        style: TextStyle(
                          color: Color(0xFFD9363E),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: enabled ? onApproveTap : null,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF096DD9),
                        disabledBackgroundColor: const Color(0xFF096DD9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '订单.审核通过'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 22 / 16,
                        ),
                      ),
                    ),
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
