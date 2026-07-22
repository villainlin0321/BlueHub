import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/route_paths.dart';
import '../../../features/files/data/file_models.dart';
import '../../../features/files/data/file_providers.dart';
import '../../auth/application/auth_role_mapper.dart';
import '../../../features/message/application/chat/chat_page_args.dart';
import '../../../shared/models/app_currency.dart';
import '../../shell/application/shell_role_provider.dart';
import '../../../shared/logging/app_log_facade.dart';
import '../../../shared/logging/app_log_scope.dart';
import '../../../shared/network/api_error_feedback.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/network/providers.dart';
import '../../../shared/network/services/file_service.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_toast.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../shared/widgets/progress_stepper.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/presentation/attachment_preview_page.dart';
import '../../../shared/widgets/sample_file_selection_dialog.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import '../../../utils/upload_picker_utils.dart';
import '../application/payment/payment_flow_coordinator.dart';
import '../data/payment_providers.dart';
import '../data/visa_order_models.dart';
import '../data/visa_order_providers.dart';
import 'order_payment_widgets.dart';

import 'package:europepass/shared/ui/test_style.dart';

class OrderDetailPageArgs {
  const OrderDetailPageArgs({required this.orderId});

  final int orderId;
}

String _orderMaterialDisplayName(MaterialVO material) {
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

class OrderDetailPage extends ConsumerStatefulWidget {
  const OrderDetailPage({
    super.key,
    this.args = const OrderDetailPageArgs(orderId: 0),
  });

  final OrderDetailPageArgs args;

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  static const Duration _paymentValidDuration = Duration(minutes: 30);
  static const Duration _paymentTickDuration = Duration(seconds: 1);
  static const int _uploadMaterialsStepNumber = 3;
  static const int _materialReviewStepNumber = 4;
  static const int _embassySubmittedStepNumber = 5;
  static const int _visaIssuedStepNumber = 6;
  final Map<String, List<PickedUploadFile>> _uploadsByRequirement =
      <String, List<PickedUploadFile>>{};
  final List<PickedUploadFile> _visaDocumentUploads = <PickedUploadFile>[];
  final Set<String> _downloadingMaterialUrls = <String>{};
  Timer? _paymentCountdownTimer;
  VisaOrderVO? _orderDetail;
  Duration _paymentRemaining = Duration.zero;
  AppPaymentMethod _selectedPaymentMethod = AppPaymentMethod.alipay;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isProcessingOrder = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadOrderDetail);
  }

  @override
  void dispose() {
    _stopPaymentCountdown();
    super.dispose();
  }

  Future<void> _loadOrderDetail() async {
    final int orderId = widget.args.orderId;
    if (orderId <= 0) {
      _stopPaymentCountdown();
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
      final bool useRejectedUploadFlow = _shouldUseRejectedUploadFlow(detail);
      if (!mounted) {
        return;
      }
      setState(() {
        _orderDetail = detail;
        _isLoading = false;
      });
      _syncRequirements(
        detail.requiredMaterials,
        materials: useRejectedUploadFlow ? detail.materials : null,
      );
      _syncVisaDocuments(detail.visaDocuments);
      _syncPendingPaymentState(detail);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _stopPaymentCountdown();
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
      return const <_MaterialRequirement>[];
    }
    return List<_MaterialRequirement>.generate(materials.length, (int index) {
      final RequiredMaterialVO item = materials[index];
      return _MaterialRequirement(
        id: 'material_${index + 1}',
        title: item.name,
        required: item.isRequired,
        exampleFileUrls: item.exampleFileUrls,
      );
    }, growable: false);
  }

  void _syncRequirements(
    List<RequiredMaterialVO>? requiredMaterials, {
    List<MaterialVO>? materials,
  }) {
    if (!mounted) {
      return;
    }
    final List<_MaterialRequirement> requirements = _buildMaterialRequirements(
      requiredMaterials,
    );
    setState(() {
      final Map<String, List<PickedUploadFile>> next = materials == null
          ? <String, List<PickedUploadFile>>{
              for (final _MaterialRequirement requirement in requirements)
                requirement.id:
                    _uploadsByRequirement[requirement.id] ??
                    <PickedUploadFile>[],
            }
          : _buildEditableUploadsByRequirement(
              requirements: requirements,
              materials: materials,
            );
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

  void _syncPendingPaymentState(VisaOrderVO detail) {
    if (!_isPendingPaymentStage(detail)) {
      _stopPaymentCountdown();
      if (!mounted) {
        return;
      }
      setState(() {
        _paymentRemaining = Duration.zero;
        _isSubmitting = false;
      });
      return;
    }

    final DateTime? createdAt = DateTime.tryParse(detail.createdAt);
    final DateTime expireAt = (createdAt ?? DateTime.now()).add(
      _paymentValidDuration,
    );
    _startPaymentCountdown(expireAt);
  }

  void _startPaymentCountdown(DateTime expireAt) {
    _stopPaymentCountdown();
    final Duration initialRemaining = _calculatePaymentRemaining(expireAt);
    if (!mounted) {
      _paymentRemaining = initialRemaining;
      return;
    }
    setState(() {
      _paymentRemaining = initialRemaining;
    });
    if (initialRemaining == Duration.zero) {
      return;
    }
    _paymentCountdownTimer = Timer.periodic(_paymentTickDuration, (_) {
      final Duration nextRemaining = _calculatePaymentRemaining(expireAt);
      if (!mounted) {
        _stopPaymentCountdown();
        return;
      }
      setState(() {
        _paymentRemaining = nextRemaining;
      });
      if (nextRemaining == Duration.zero) {
        _stopPaymentCountdown();
      }
    });
  }

  void _stopPaymentCountdown() {
    _paymentCountdownTimer?.cancel();
    _paymentCountdownTimer = null;
  }

  Duration _calculatePaymentRemaining(DateTime expireAt) {
    final Duration remaining = expireAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
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
      fileSizeBytes: null,
      progress: 1,
    );
  }

  PickedUploadFile _buildPickedUploadFileFromMaterial(MaterialVO material) {
    final String normalizedPath = _normalizedPathFromUrl(material.fileUrl);
    final String rejectReason = (material.rejectReason ?? '').trim();
    return PickedUploadFile(
      id: 'material_${material.materialId}_${material.fileUrl.hashCode}_${material.uploadedAt}',
      name: _materialDisplayName(material),
      path: normalizedPath.isEmpty ? material.fileUrl : normalizedPath,
      sourceType: UploadSourceType.file,
      state: rejectReason.isEmpty
          ? UploadItemState.success
          : UploadItemState.failure,
      isImage: material.fileType.trim().toLowerCase().startsWith('image/'),
      sizeLabel: material.fileSize > 0
          ? UploadPickerUtils.formatFileSize(material.fileSize)
          : null,
      errorMessage: rejectReason.isEmpty ? null : rejectReason,
      progress: 1,
      // 详情接口未返回原始 fileId，驳回重传场景先复用材料记录 ID 保持回显文件可提交。
      uploadedFileId: material.materialId > 0 ? material.materialId : null,
      uploadedFileUrl: material.fileUrl,
      fileSizeBytes: material.fileSize > 0 ? material.fileSize : null,
    );
  }

  Map<String, List<PickedUploadFile>> _buildEditableUploadsByRequirement({
    required List<_MaterialRequirement> requirements,
    required List<MaterialVO> materials,
  }) {
    final Map<String, List<PickedUploadFile>> uploadsByRequirement =
        <String, List<PickedUploadFile>>{
          for (final _MaterialRequirement requirement in requirements)
            requirement.id: <PickedUploadFile>[
              ...(_uploadsByRequirement[requirement.id] ??
                  const <PickedUploadFile>[]),
            ],
        };
    final Map<String, _MaterialRequirement> requirementByTitle =
        <String, _MaterialRequirement>{
          for (final _MaterialRequirement requirement in requirements)
            requirement.title.trim(): requirement,
        };
    final Set<String> existingKeys = <String>{
      for (final List<PickedUploadFile> files in uploadsByRequirement.values)
        for (final PickedUploadFile file in files)
          '${(file.uploadedFileUrl ?? '').trim()}|${file.name.trim()}',
    };

    for (final MaterialVO material in materials) {
      final _MaterialRequirement? requirement =
          requirementByTitle[material.materialName.trim()];
      if (requirement == null) {
        continue;
      }
      final PickedUploadFile file = _buildPickedUploadFileFromMaterial(
        material,
      );
      final String dedupeKey =
          '${(file.uploadedFileUrl ?? '').trim()}|${file.name.trim()}';
      if (!existingKeys.add(dedupeKey)) {
        continue;
      }
      uploadsByRequirement[requirement.id]!.add(file);
    }

    return uploadsByRequirement;
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
      final String normalizedPath = _normalizedPathFromUrl(material.fileUrl);
      final String rejectReason = (material.rejectReason ?? '').trim();
      uploadsByRequirement[requirement.id]!.add(
        PickedUploadFile(
          id: '${requirement.id}_${material.fileUrl.hashCode}_${material.uploadedAt}',
          name: _materialDisplayName(material),
          path: normalizedPath.isEmpty ? material.fileUrl : normalizedPath,
          sourceType: UploadSourceType.file,
          state: rejectReason.isEmpty
              ? UploadItemState.success
              : UploadItemState.failure,
          isImage: material.fileType.trim().toLowerCase().startsWith('image/'),
          sizeLabel: material.fileSize > 0
              ? UploadPickerUtils.formatFileSize(material.fileSize)
              : null,
          errorMessage: rejectReason.isEmpty ? null : rejectReason,
          uploadedFileUrl: material.fileUrl,
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
      return const <ProgressStep>[];
    }
    final int currentStep = _displayCurrentStep(detail);
    return steps
        .map((StepVO step) {
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

  int _displayCurrentStep(VisaOrderVO? detail) {
    if (_shouldUseRejectedUploadFlow(detail)) {
      return _uploadMaterialsStepNumber;
    }
    return detail?.currentStep ?? 0;
  }

  void _showMessage(String message) {
    AppToast.show(message);
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
        targetUserRole: visaProviderRoleId,
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

  void _handleContactTap() {
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.客户信息加载中'.tr());
      return;
    }
    final int targetUserId = detail.contactTargetUserId;
    if (targetUserId <= 0) {
      _showMessage('订单.客户信息缺失'.tr());
      return;
    }
    context.push(
      RoutePaths.chat,
      extra: ChatPageArgs(
        targetUserId: targetUserId,
        targetUserRole: detail.contactTargetUserRole,
        nickname: _customerNameFor(detail),
        avatarUrl: detail.avatarUrl,
        relatedOrderId: detail.orderId,
        packageName: _serviceNameFor(detail),
        orderStatus: detail.statusLabel,
      ),
    );
  }

  String _customerNameFor(VisaOrderVO detail) {
    final String nickname = detail.nickname.trim();
    if (nickname.isNotEmpty) {
      return nickname;
    }
    return '订单.订单客户'.tr();
  }

  String _serviceNameFor(VisaOrderVO detail) {
    final String packageName = detail.packageName.trim();
    if (packageName.isNotEmpty) {
      return packageName;
    }
    final String tierName = detail.tierName.trim();
    if (tierName.isNotEmpty) {
      return tierName;
    }
    return '订单.签证服务'.tr();
  }

  List<PickedUploadFile> _filesFor(_MaterialRequirement requirement) {
    return _uploadsByRequirement[requirement.id] ?? const <PickedUploadFile>[];
  }

  String _currentStepLabel(VisaOrderVO? detail) {
    if (detail == null) {
      return '';
    }
    for (final StepVO step in detail.steps) {
      if (step.step == _displayCurrentStep(detail)) {
        return step.label.trim();
      }
    }
    return detail.statusLabel.trim();
  }

  bool _isUploadMaterialsStage(VisaOrderVO? detail) {
    if (_shouldUseRejectedUploadFlow(detail)) {
      return true;
    }
    final String currentStepLabel = _currentStepLabel(detail);
    final String status = detail?.status.trim().toLowerCase() ?? '';
    return (detail?.currentStep ?? 0) == _uploadMaterialsStepNumber ||
        currentStepLabel.contains('订单.上传材料'.tr()) ||
        status.contains('upload');
  }

  bool _isPendingPaymentStage(VisaOrderVO? detail) {
    return (detail?.status.trim().toLowerCase() ?? '') == 'pending_payment';
  }

  bool _isMaterialReviewStage(VisaOrderVO? detail) {
    if (_shouldUseRejectedUploadFlow(detail)) {
      return false;
    }
    final String currentStepLabel = _currentStepLabel(detail);
    final String status = detail?.status.trim().toLowerCase() ?? '';
    return (detail?.currentStep ?? 0) == _materialReviewStepNumber ||
        currentStepLabel.contains('订单.材料审核'.tr()) ||
        status.contains('review');
  }

  bool _isRejectedStatus(VisaOrderVO? detail) {
    return (detail?.status.trim().toLowerCase() ?? '') == 'rejected';
  }

  bool _shouldUseRejectedUploadFlow(VisaOrderVO? detail) {
    return !_isServiceProviderRole &&
        _isRejectedStatus(detail) &&
        (detail?.currentStep ?? 0) == _materialReviewStepNumber;
  }

  bool get _isServiceProviderRole =>
      ref.read(shellRoleProvider) == ShellRole.serviceProvider;

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

  /// 构建订单详情页支付交互的统一日志上下文，避免点击事件缺少关键订单定位字段。
  Map<String, Object?> _buildPaymentInteractionLogContext(VisaOrderVO detail) {
    return <String, Object?>{
      'route': RoutePaths.orderDetail,
      'module': 'order',
      'feature': 'order_detail',
      'source': 'order_detail_pay_now',
      'orderId': detail.orderId,
      'paymentMethod': _selectedPaymentMethod.apiValue,
      if (detail.status.trim().isNotEmpty) 'orderStatus': detail.status.trim(),
      if (detail.currentStep > 0) 'currentStep': detail.currentStep,
    };
  }

  Future<void> _handlePayNow() async {
    if (_isSubmitting) {
      return;
    }
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.订单详情尚未加载完成'.tr());
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await AppLogScope.run<Future<void>>(
        traceId: buildAppTraceId('order_detail_payment'),
        fields: _buildPaymentInteractionLogContext(detail),
        action: () async {
          // 订单详情页直接支付没有二次弹层，因此点击日志必须落在真正发起支付前。
          ActionLog.tap(
            event: 'ORDER_PAYMENT_CONFIRM_TAP',
            message: '用户在订单详情页点击立即支付',
          );
          final PaymentFlowResult result = await ref
              .read(paymentFlowCoordinatorProvider)
              .startPayment(
                orderId: detail.orderId,
                method: _selectedPaymentMethod,
              );
          if (!mounted) {
            return;
          }
          switch (result.status) {
            case PaymentFlowStatus.success:
              await _handlePaymentSuccess();
              return;
            case PaymentFlowStatus.cancel:
            case PaymentFlowStatus.failed:
            case PaymentFlowStatus.pending:
              setState(() => _isSubmitting = false);
              _showMessage(result.message);
              return;
          }
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      _showMessage(resolveOrderPaymentErrorMessage(context, error));
    }
  }

  Future<void> _handlePaymentSuccess() async {
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
    ref.read(orderRefreshTickProvider.notifier).bump();
    if (!mounted) {
      return;
    }
    await _loadOrderDetail();
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
          await UploadPickerUtils.pickPdfFiles();
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
          await UploadPickerUtils.pickPdfFiles();
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
        '订单.请先上传'.tr(
          namedArgs: <String, String>{'title': missingRequirement.title},
        ),
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
          final int fileSize =
              file.fileSizeBytes ?? UploadPickerUtils.readFileSize(file.path);
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
      _showMessage(_resolveErrorMessage(error, fallback: '订单.提交材料失败'.tr()));
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
      _showMessage(_resolveErrorMessage(error, fallback: '订单.上传出证材料失败'.tr()));
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
    return ApiErrorFeedback.resolveMessage(error, fallback: fallback);
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final List<Directory> candidates = <Directory>[];
    if (Platform.isAndroid) {
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
    } else if (Platform.isIOS) {
      try {
        final Directory temporaryDirectory = await getTemporaryDirectory();
        candidates.add(Directory('${temporaryDirectory.path}/downloads'));
      } catch (_) {}
    } else {
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
    }

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
    return _orderMaterialDisplayName(material);
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

  List<MaterialVO> _buildRequirementExampleMaterials(
    _MaterialRequirement requirement,
  ) {
    final Set<String> uniqueUrls = <String>{};
    final List<MaterialVO> materials = <MaterialVO>[];
    for (final String rawUrl in requirement.exampleFileUrls) {
      final String fileUrl = rawUrl.trim();
      if (fileUrl.isEmpty || !uniqueUrls.add(fileUrl)) {
        continue;
      }
      materials.add(
        MaterialVO(
          materialId: 0,
          materialName: _buildRequirementExampleName(requirement, fileUrl),
          fileUrl: fileUrl,
          fileType: _inferRequirementExampleFileType(fileUrl),
          fileSize: 0,
          uploadedAt: '',
          rejectReason: null,
        ),
      );
    }
    return materials;
  }

  String _buildRequirementExampleName(
    _MaterialRequirement requirement,
    String fileUrl,
  ) {
    final Uri? uri = Uri.tryParse(fileUrl);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      final String lastSegment = Uri.decodeComponent(uri.pathSegments.last);
      if (lastSegment.trim().isNotEmpty) {
        return lastSegment;
      }
    }
    return requirement.title;
  }

  String _inferRequirementExampleFileType(String fileUrl) {
    final String lowerUrl = fileUrl.trim().toLowerCase();
    if (lowerUrl.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerUrl.endsWith('.jpg') || lowerUrl.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerUrl.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerUrl.endsWith('.pdf')) {
      return 'application/pdf';
    }
    return 'application/octet-stream';
  }

  /// 判断材料 MIME 是否属于图片，优先复用后端返回的文件类型信息。
  bool _isImageFileType(String fileType) {
    return fileType.trim().toLowerCase().startsWith('image/');
  }

  /// 判断材料 MIME 或路径是否属于 PDF，兼容后端未稳定返回扩展名的场景。
  bool _isPdfMaterial({
    required String fileType,
    required String fileUrl,
    required String fileName,
  }) {
    final String normalizedType = fileType.trim().toLowerCase();
    if (normalizedType == 'application/pdf' ||
        normalizedType.endsWith('/pdf')) {
      return true;
    }
    return UploadPickerUtils.isPdfPath(fileUrl) ||
        UploadPickerUtils.isPdfPath(fileName);
  }

  /// 打开订单材料预览，图片和 PDF 都优先使用应用内预览。
  Future<void> _openMaterialPreview(MaterialVO material) async {
    final String fileUrl = material.fileUrl.trim();
    if (fileUrl.isEmpty) {
      _showMessage('订单.文件地址不存在'.tr());
      return;
    }
    await openAttachmentPreview(
      context,
      path: fileUrl,
      title: _materialDisplayName(material),
      isImage: _isImageFileType(material.fileType),
      isPdf: _isPdfMaterial(
        fileType: material.fileType,
        fileUrl: fileUrl,
        fileName: _materialDisplayName(material),
      ),
    );
  }

  /// 打开本地或远程已选文件预览，优先使用上传后的 URL，缺失时回退到本地路径。
  Future<void> _openPickedFilePreview(PickedUploadFile file) async {
    final String previewPath = (file.uploadedFileUrl ?? file.path).trim();
    if (previewPath.isEmpty) {
      _showMessage('订单.文件地址不存在'.tr());
      return;
    }
    await openAttachmentPreview(
      context,
      path: previewPath,
      title: file.name,
      isImage: file.isImage,
      isPdf:
          UploadPickerUtils.isPdfPath(previewPath) ||
          UploadPickerUtils.isPdfPath(file.name),
    );
  }

  /// 生成已选文件的下载状态键，优先使用服务端 URL，缺失时回退到本地路径。
  String _pickedFileDownloadKey(PickedUploadFile file) {
    final String uploadedFileUrl = (file.uploadedFileUrl ?? '').trim();
    if (uploadedFileUrl.isNotEmpty) {
      return uploadedFileUrl;
    }
    return file.path.trim();
  }

  /// 解析已选文件的扩展名，避免下载后丢失原始文件类型。
  String _pickedFileExtension(PickedUploadFile file) {
    final String fileName = file.name.trim();
    final int fileNameDotIndex = fileName.lastIndexOf('.');
    if (fileNameDotIndex > 0) {
      return fileName.substring(fileNameDotIndex);
    }

    final String uploadedFileUrl = (file.uploadedFileUrl ?? '').trim();
    if (uploadedFileUrl.isNotEmpty) {
      final String remotePath =
          Uri.tryParse(uploadedFileUrl)?.path ?? uploadedFileUrl;
      final String remoteName = UploadPickerUtils.basename(remotePath);
      final int remoteDotIndex = remoteName.lastIndexOf('.');
      if (remoteDotIndex > 0) {
        return remoteName.substring(remoteDotIndex);
      }
    }

    final String localPath = file.path.trim();
    final String localName = UploadPickerUtils.basename(localPath);
    final int localDotIndex = localName.lastIndexOf('.');
    if (localDotIndex > 0) {
      return localName.substring(localDotIndex);
    }
    return '';
  }

  /// 判断下载地址是否指向外部对象存储；这类预签名 URL 不能附带业务鉴权头。
  bool _shouldUseAnonymousDownloadDio(String url) {
    final Uri? downloadUri = Uri.tryParse(url);
    final Uri? apiBaseUri = Uri.tryParse(ref.read(appConfigProvider).baseUrl);
    if (downloadUri == null || !downloadUri.hasScheme || apiBaseUri == null) {
      return false;
    }
    return downloadUri.host.isNotEmpty &&
        apiBaseUri.host.isNotEmpty &&
        downloadUri.host != apiBaseUri.host;
  }

  /// 为下载场景选择合适的 Dio；对象存储预签名链接使用无鉴权客户端，避免 400。
  (Dio dio, bool shouldClose) _createDownloadDio(String url) {
    if (_shouldUseAnonymousDownloadDio(url)) {
      return (
        Dio(
          BaseOptions(
            connectTimeout: const Duration(seconds: 20),
            receiveTimeout: const Duration(seconds: 60),
            sendTimeout: const Duration(seconds: 60),
          ),
        ),
        true,
      );
    }
    return (ref.read(dioProvider), false);
  }

  /// iOS 下载完成后拉起系统分享/保存面板，由用户选择保存到“文件 App”中的位置。
  Future<void> _presentIosSavePanel({
    required String savePath,
    required String fileName,
  }) async {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        title: fileName,
        subject: fileName,
        files: <XFile>[XFile(savePath, name: fileName)],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  /// 下载已选文件；远程文件走鉴权下载，本地文件复制到目标目录，统一沉淀到系统文件夹。
  Future<bool> _downloadPickedUploadFile(PickedUploadFile file) async {
    final String downloadKey = _pickedFileDownloadKey(file);
    if (downloadKey.isEmpty) {
      _showMessage('订单.文件地址不存在'.tr());
      return false;
    }
    if (_downloadingMaterialUrls.contains(downloadKey)) {
      return false;
    }

    setState(() {
      _downloadingMaterialUrls.add(downloadKey);
    });

    final String uploadedFileUrl = (file.uploadedFileUrl ?? '').trim();
    final String filePath = file.path.trim();
    final String remoteFileUrl = uploadedFileUrl.isNotEmpty
        ? uploadedFileUrl
        : _isNetworkFilePath(filePath)
        ? filePath
        : '';
    final String downloadUrl = remoteFileUrl.isNotEmpty
        ? remoteFileUrl
        : filePath;
    final (Dio dio, bool shouldCloseDio) = _createDownloadDio(downloadUrl);
    try {
      final Directory directory = await _resolveDownloadDirectory();
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
      }

      final String extension = _pickedFileExtension(file);
      final String normalizedName = file.name.contains('.') || extension.isEmpty
          ? file.name
          : '${file.name}$extension';
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

      if (remoteFileUrl.isNotEmpty) {
        await dio.download(
          remoteFileUrl,
          savePath,
          options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 60),
          ),
          deleteOnError: true,
        );
      } else {
        final File localFile = File(filePath);
        if (!localFile.existsSync()) {
          _showMessage('订单.文件地址不存在'.tr());
          return false;
        }
        await localFile.copy(savePath);
      }

      if (!mounted) {
        return false;
      }
      if (Platform.isIOS) {
        await _presentIosSavePanel(savePath: savePath, fileName: sanitizedName);
        return true;
      }
      _showMessage('${'订单.已下载到本地'.tr()}\n$savePath');
      return true;
    } on DioException {
      if (!mounted) {
        return false;
      }
      _showMessage('订单.文件下载失败'.tr());
    } catch (error) {
      if (!mounted) {
        return false;
      }
      _showMessage(_resolveErrorMessage(error, fallback: '订单.文件下载失败'.tr()));
    } finally {
      if (shouldCloseDio) {
        dio.close(force: true);
      }
      if (mounted) {
        setState(() {
          _downloadingMaterialUrls.remove(downloadKey);
        });
      }
    }
    return false;
  }

  Future<void> _handleRequirementPreview(
    _MaterialRequirement requirement,
  ) async {
    final List<MaterialVO> exampleMaterials = _buildRequirementExampleMaterials(
      requirement,
    );
    if (exampleMaterials.isEmpty) {
      _showMessage('订单.文件地址不存在'.tr());
      return;
    }
    // if (exampleMaterials.length == 1) {
    //   await _downloadAndOpenMaterial(
    //     exampleMaterials.first,
    //     showPageLoading: true,
    //   );
    //   return;
    // }
    if (!mounted) {
      return;
    }

    await showAppDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return SampleFileSelectionDialog(
          title: requirement.title,
          itemCount: exampleMaterials.length,
          itemBuilder: (BuildContext context, int index) {
            final MaterialVO material = exampleMaterials[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == exampleMaterials.length - 1 ? 0 : 12,
              ),
              child: SampleFileSelectionItem(
                title: _materialDisplayName(material),
                subtitle: UploadPickerUtils.formatFileSize(material.fileSize),
                fileUrl: material.fileUrl,
                fileType: material.fileType,
                onTap: () async {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  await _openMaterialPreview(material);
                },
                isDownloading: _downloadingMaterialUrls.contains(
                  material.fileUrl.trim(),
                ),
                onDownloadTap: () async {
                  final bool success = await _downloadMaterialFile(
                    material,
                    showPageLoading: true,
                  );
                  if (!success || !dialogContext.mounted) {
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _downloadMaterialFile(
    MaterialVO material, {
    bool openAfterDownload = false,
    bool showPageLoading = false,
  }) async {
    final String fileUrl = material.fileUrl.trim();
    if (fileUrl.isEmpty) {
      _showMessage('订单.文件地址不存在'.tr());
      return false;
    }
    if (_downloadingMaterialUrls.contains(fileUrl)) {
      return false;
    }

    setState(() {
      _downloadingMaterialUrls.add(fileUrl);
    });

    final (Dio dio, bool shouldCloseDio) = _createDownloadDio(fileUrl);
    bool didShowPageLoading = false;

    Future<void> dismissPageLoading() async {
      if (!didShowPageLoading || !EasyLoading.isShow) {
        return;
      }
      await EasyLoading.dismiss();
      didShowPageLoading = false;
    }

    try {
      if (showPageLoading) {
        await EasyLoading.show(maskType: EasyLoadingMaskType.black);
        didShowPageLoading = true;
      }
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
        await dismissPageLoading();
        return false;
      }
      if (Platform.isIOS && !openAfterDownload) {
        await dismissPageLoading();
        await _presentIosSavePanel(savePath: savePath, fileName: sanitizedName);
        return true;
      }
      if (openAfterDownload) {
        await dismissPageLoading();
        final OpenResult openResult = await OpenFilex.open(savePath);
        if (openResult.type != ResultType.done) {
          final String message = openResult.message.trim();
          _showMessage(message.isEmpty ? '订单.文件打开失败'.tr() : message);
          return false;
        }
        return true;
      }
      await dismissPageLoading();
      _showMessage('${'订单.已下载到本地'.tr()}\n$savePath');
      return true;
    } on DioException {
      await dismissPageLoading();
      if (!mounted) {
        return false;
      }
      _showMessage('订单.文件下载失败'.tr());
    } catch (error) {
      await dismissPageLoading();
      if (!mounted) {
        return false;
      }
      _showMessage(_resolveErrorMessage(error, fallback: '订单.文件下载失败'.tr()));
    } finally {
      if (shouldCloseDio) {
        dio.close(force: true);
      }
      if (mounted) {
        setState(() {
          _downloadingMaterialUrls.remove(fileUrl);
        });
      }
      await dismissPageLoading();
    }
    return false;
  }

  Future<_RejectReasonSubmitResult?> _showRejectReasonDialog(
    List<MaterialVO> materials,
  ) async {
    return showModalBottomSheet<_RejectReasonSubmitResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (BuildContext sheetContext) {
        return _RejectReasonBottomSheet(
          materials: materials,
          onClose: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  Future<void> _processOrder({
    required String action,
    String? nextStatus,
    String? remark,
    List<OrderMaterialRejectionBO>? materialRejections,
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
              materialRejections: materialRejections,
              nextStatus: nextStatus,
            ),
          );
      if (!mounted) {
        return;
      }
      ref.read(orderRefreshTickProvider.notifier).bump();
      if (context.canPop()) {
        context.pop(true);
        return;
      }
      await _loadOrderDetail();
      if (!mounted) {
        return;
      }
      _showMessage(action == 'approve' ? '订单.审核已通过'.tr() : '订单.已驳回重传'.tr());
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
    await _processOrder(action: 'approve', nextStatus: 'embassy_submitted');
  }

  Future<void> _handleRejectOrder() async {
    final VisaOrderVO? detail = _orderDetail;
    if (detail == null) {
      _showMessage('订单.订单详情尚未加载完成'.tr());
      return;
    }
    if (detail.materials.isEmpty) {
      _showMessage('暂无可驳回材料');
      return;
    }
    final _RejectReasonSubmitResult? result = await _showRejectReasonDialog(
      detail.materials,
    );
    if (result == null || result.materialRejections.isEmpty) {
      return;
    }
    await _processOrder(
      action: 'reject',
      materialRejections: result.materialRejections,
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
    final bool isPendingPaymentStage = _isPendingPaymentStage(detail);
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
          style: TestStyle.pingFangSemibold(
            fontSize: 17,
            color: const Color(0xE6000000),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: isServiceProvider ? _handleContactTap : _handleConsultTap,
            child: Text(
              isServiceProvider ? '订单.联系客户'.tr() : '订单.联系商家'.tr(),
              style: TestStyle.pingFangRegular(
                fontSize: 14,
                color: const Color(0xFF262626),
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
        isPendingPaymentStage: isPendingPaymentStage,
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
        isPendingPaymentStage: isPendingPaymentStage,
        isUploadMaterialsStage: isUploadMaterialsStage,
        isMaterialReviewStage: isMaterialReviewStage,
        isEmbassySubmittedStage: isEmbassySubmittedStage,
      ),
    );
  }

  Widget _buildBottomNavigationBar({
    required VisaOrderVO? detail,
    required bool isServiceProvider,
    required bool isPendingPaymentStage,
    required bool isUploadMaterialsStage,
    required bool isMaterialReviewStage,
    required bool isEmbassySubmittedStage,
  }) {
    if (detail == null) {
      return const SizedBox.shrink();
    }
    if (isPendingPaymentStage && !isServiceProvider) {
      return _BottomSubmitBar(
        label: _isSubmitting ? '服务详情.支付中'.tr() : '服务详情.立即支付'.tr(),
        enabled: !_isLoading && _errorMessage == null && !_isSubmitting,
        onPressed: _handlePayNow,
      );
    }
    if (_isRejectedStatus(detail) && !_shouldUseRejectedUploadFlow(detail)) {
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
    required bool isPendingPaymentStage,
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
    final List<ProgressStep> progressSteps = _buildProgressSteps(detail);
    final bool showApplicantMaterialCard =
        shouldShowApplicantMaterialCard && requirements.isNotEmpty;
    final bool showPendingPaymentSection =
        !isServiceProvider && isPendingPaymentStage;
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        if (progressSteps.isNotEmpty)
          _OrderProgressStepper(steps: progressSteps),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          child: _OrderInfoCard(order: detail),
        ),
        if (showPendingPaymentSection)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
            child: OrderPaymentAmountCard(
              amount: detail.amount,
              currency: detail.currency,
              remaining: _paymentRemaining,
            ),
          ),
        if (showPendingPaymentSection)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: OrderPaymentMethodCard(
              selectedMethod: _selectedPaymentMethod,
              onSelected: (AppPaymentMethod method) {
                setState(() => _selectedPaymentMethod = method);
              },
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: isServiceProvider
              ? shouldShowProviderMaterialCard
                    ? _ProviderMaterialReviewCard(
                        materials: detail.materials,
                        downloadingFileUrls: _downloadingMaterialUrls,
                        onPreviewTap: _openMaterialPreview,
                        onDownloadTap: (MaterialVO material) async {
                          await _downloadMaterialFile(material);
                        },
                      )
                    : const SizedBox.shrink()
              : showApplicantMaterialCard
              ? _MaterialUploadCard(
                  requirements: requirements,
                  uploadsByRequirement: displayedUploadsByRequirement,
                  downloadingFileKeys: _downloadingMaterialUrls,
                  allowUpload: isUploadMaterialsStage,
                  allowDelete: isUploadMaterialsStage,
                  onPreviewTap: _handleRequirementPreview,
                  onPreviewFile: _openPickedFilePreview,
                  onDownloadFile: _downloadPickedUploadFile,
                  onUploadTap: _openUploadSheet,
                  onDeleteFile: _removeUploadFile,
                )
              : const SizedBox.shrink(),
        ),
        if (isEmbassySubmittedStage || isVisaIssuedStage)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: _ProviderVisaDocumentUploadCard(
              files: _visaDocumentUploads,
              downloadingFileKeys: _downloadingMaterialUrls,
              allowUpload: isServiceProvider && isEmbassySubmittedStage,
              allowDelete: isServiceProvider && isEmbassySubmittedStage,
              onUploadTap: _openVisaDocumentUploadSheet,
              onPreviewFile: _openPickedFilePreview,
              onDownloadFile: _downloadPickedUploadFile,
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
            style: TestStyle.pingFangMedium(
              fontSize: 14,
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
            value: _formatAmount(order.amount, order.currency),
          ),
          const SizedBox(height: 8),
          _OrderInfoRow(label: '订单.订单号'.tr(), value: order.orderNo),
        ],
      ),
    );
  }

  static String _formatAmount(double amount, String? currency) {
    return AppCurrency.formatAmount(
      amount,
      currency,
      fractionDigitsWhenNeeded: 2,
      trimTrailingZeros: false,
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
          style: TestStyle.regular(
            fontSize: 12,
            color: const Color(0xFF8C8C8C),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TestStyle.regular(
              fontSize: 12,
              color: const Color(0xFF8C8C8C),
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
    required this.downloadingFileKeys,
    required this.allowUpload,
    required this.allowDelete,
    required this.onPreviewTap,
    required this.onPreviewFile,
    required this.onDownloadFile,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final List<_MaterialRequirement> requirements;
  final Map<String, List<PickedUploadFile>> uploadsByRequirement;
  final Set<String> downloadingFileKeys;
  final bool allowUpload;
  final bool allowDelete;
  final ValueChanged<_MaterialRequirement> onPreviewTap;
  final ValueChanged<PickedUploadFile> onPreviewFile;
  final ValueChanged<PickedUploadFile> onDownloadFile;
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
              downloadingFileKeys: downloadingFileKeys,
              allowUpload: allowUpload,
              allowDelete: allowDelete,
              onPreviewTap: () => onPreviewTap(item),
              onPreviewFile: onPreviewFile,
              onDownloadFile: onDownloadFile,
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
    required this.downloadingFileKeys,
    required this.allowUpload,
    required this.allowDelete,
    required this.onUploadTap,
    required this.onPreviewFile,
    required this.onDownloadFile,
    required this.onDeleteFile,
  });

  final List<PickedUploadFile> files;
  final Set<String> downloadingFileKeys;
  final bool allowUpload;
  final bool allowDelete;
  final VoidCallback onUploadTap;
  final ValueChanged<PickedUploadFile> onPreviewFile;
  final ValueChanged<PickedUploadFile> onDownloadFile;
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
            allowUpload ? '订单.添加出证材料'.tr() : '订单.出证材料'.tr(),
            style: TestStyle.pingFangRegular(
              fontSize: 14,
              color: const Color(0xFF171A1D),
            ),
          ),
          const SizedBox(height: 12),
          _MaterialUploadContent(
            files: files,
            downloadingFileKeys: downloadingFileKeys,
            allowUpload: allowUpload,
            allowDelete: allowDelete,
            emptyReadonlyText: '订单.暂无出证材料'.tr(),
            onAddTap: onUploadTap,
            onPreviewFile: onPreviewFile,
            onDownloadFile: onDownloadFile,
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
    this.onPreviewTap,
    this.onDownloadTap,
  });

  final List<MaterialVO> materials;
  final Set<String> downloadingFileUrls;
  final Future<void> Function(MaterialVO)? onPreviewTap;
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
                  style: TestStyle.pingFangMedium(
                    fontSize: 16,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
              Text(
                '订单.共份'.tr(
                  namedArgs: <String, String>{
                    'count': materials.length.toString(),
                  },
                ),
                style: TestStyle.regular(
                  fontSize: 14,
                  color: const Color(0xFF8C8C8C),
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
                child: SampleFileSelectionItem(
                  title: _orderMaterialDisplayName(material),
                  subtitle: UploadPickerUtils.formatFileSize(material.fileSize),
                  fileUrl: material.fileUrl,
                  fileType: material.fileType,
                  onTap: onPreviewTap == null
                      ? null
                      : () => onPreviewTap!(material),
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

class _MaterialUploadItem extends StatelessWidget {
  const _MaterialUploadItem({
    required this.requirement,
    required this.files,
    required this.downloadingFileKeys,
    required this.allowUpload,
    required this.allowDelete,
    required this.onPreviewTap,
    required this.onPreviewFile,
    required this.onDownloadFile,
    required this.onUploadTap,
    required this.onDeleteFile,
  });

  final _MaterialRequirement requirement;
  final List<PickedUploadFile> files;
  final Set<String> downloadingFileKeys;
  final bool allowUpload;
  final bool allowDelete;
  final VoidCallback onPreviewTap;
  final ValueChanged<PickedUploadFile> onPreviewFile;
  final ValueChanged<PickedUploadFile> onDownloadFile;
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
                      style: TestStyle.regular(
                        fontSize: 14,
                        color: const Color(0xFF171A1D),
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
                style: TestStyle.pingFangRegular(
                  fontSize: 13,
                  color: const Color(0xFF096DD9),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MaterialUploadContent(
          files: files,
          downloadingFileKeys: downloadingFileKeys,
          allowUpload: allowUpload,
          allowDelete: allowDelete,
          onAddTap: onUploadTap,
          onPreviewFile: onPreviewFile,
          onDownloadFile: onDownloadFile,
          onDeleteFile: onDeleteFile,
        ),
      ],
    );
  }
}

class _MaterialUploadContent extends StatelessWidget {
  const _MaterialUploadContent({
    required this.files,
    required this.downloadingFileKeys,
    required this.allowUpload,
    required this.allowDelete,
    this.emptyReadonlyText = '',
    required this.onAddTap,
    this.onPreviewFile,
    this.onDownloadFile,
    required this.onDeleteFile,
  });

  final List<PickedUploadFile> files;
  final Set<String> downloadingFileKeys;
  final bool allowUpload;
  final bool allowDelete;
  final String emptyReadonlyText;
  final VoidCallback? onAddTap;
  final ValueChanged<PickedUploadFile>? onPreviewFile;
  final ValueChanged<PickedUploadFile>? onDownloadFile;
  final ValueChanged<PickedUploadFile>? onDeleteFile;

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      if (allowUpload && onAddTap != null) {
        return _UploadPlaceholder(onTap: onAddTap!);
      }
      return _ReadonlyUploadPlaceholder(
        text: emptyReadonlyText.isNotEmpty
            ? emptyReadonlyText
            : '订单.待求职者上传材料'.tr(),
      );
    }

    return Column(
      children: <Widget>[
        ...List<Widget>.generate(files.length, (int index) {
          final PickedUploadFile file = files[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _UploadFileCard(
              file: file,
              isDownloading: downloadingFileKeys.contains(
                (file.uploadedFileUrl ?? '').trim().isNotEmpty
                    ? file.uploadedFileUrl!.trim()
                    : file.path.trim(),
              ),
              onPreviewTap: onPreviewFile == null
                  ? null
                  : () => onPreviewFile!(file),
              onDownloadTap: onDownloadFile == null
                  ? null
                  : () => onDownloadFile!(file),
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
    this.isDownloading = false,
    this.onPreviewTap,
    this.onDownloadTap,
    this.onRemoveTap,
    this.showRemoveButton = true,
  });

  final PickedUploadFile file;
  final bool isDownloading;
  final VoidCallback? onPreviewTap;
  final VoidCallback? onDownloadTap;
  final VoidCallback? onRemoveTap;
  final bool showRemoveButton;

  bool get _showsRemoveButton => showRemoveButton && onRemoveTap != null;

  bool get _showsDownloadButton {
    if (onDownloadTap == null ||
        file.state == UploadItemState.uploading ||
        _showsRemoveButton) {
      return false;
    }
    if (file.state == UploadItemState.success) {
      return true;
    }
    return _hasRemoteDownloadSource(file);
  }

  /// 将统一的卡片内容按需包装为可点击预览的交互容器。
  Widget _wrapPreviewTap(Widget child) {
    if (onPreviewTap == null) {
      return child;
    }
    return InkWell(
      onTap: onPreviewTap,
      borderRadius: BorderRadius.circular(8),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (file.state) {
      case UploadItemState.uploading:
        return _wrapPreviewTap(
          _UploadFileCardFrame(
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
                        style: TestStyle.regular(
                          fontSize: 14,
                          color: const Color(0xFF333333),
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
          ),
        );
      case UploadItemState.success:
        return _wrapPreviewTap(
          _UploadFileCardFrame(
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
                        style: TestStyle.regular(
                          fontSize: 14,
                          color: const Color(0xFF333333),
                        ),
                      ),
                      if (file.sizeLabel != null) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          file.sizeLabel!,
                          style: TestStyle.regular(
                            fontSize: 12,
                            color: const Color(0xFF8C8C8C),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_showsDownloadButton) ...<Widget>[
                  _DownloadUploadButton(
                    onTap: onDownloadTap!,
                    isDownloading: isDownloading,
                  ),
                  const SizedBox(width: 8),
                ],
                if (_showsRemoveButton)
                  _RemoveUploadButton(onTap: onRemoveTap!),
              ],
            ),
          ),
        );
      case UploadItemState.failure:
        return _wrapPreviewTap(
          _UploadFileCardFrame(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 9),
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
                        style: TestStyle.pingFangRegular(
                          fontSize: 14,
                          color: const Color(0xFFFF3141),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (file.errorMessage ?? '订单.上传失败请重试'.tr()).trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TestStyle.pingFangRegular(
                          fontSize: 11,
                          color: const Color(0xFFFF3141),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_showsDownloadButton) ...<Widget>[
                  _DownloadUploadButton(
                    onTap: onDownloadTap!,
                    isDownloading: isDownloading,
                  ),
                  const SizedBox(width: 8),
                ],
                if (_showsRemoveButton)
                  _RemoveUploadButton(onTap: onRemoveTap!),
              ],
            ),
          ),
        );
    }
  }
}

bool _isNetworkFilePath(String value) {
  final String normalizedValue = value.trim().toLowerCase();
  return normalizedValue.startsWith('http://') ||
      normalizedValue.startsWith('https://');
}

bool _hasRemoteDownloadSource(PickedUploadFile file) {
  final String uploadedFileUrl = (file.uploadedFileUrl ?? '').trim();
  if (uploadedFileUrl.isNotEmpty) {
    return true;
  }
  return _isNetworkFilePath(file.path);
}

class _UploadFileCardFrame extends StatelessWidget {
  const _UploadFileCardFrame({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: padding,
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

class _DownloadUploadButton extends StatelessWidget {
  const _DownloadUploadButton({
    required this.onTap,
    required this.isDownloading,
  });

  final VoidCallback onTap;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDownloading ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 20,
        height: 20,
        child: Center(
          // 下载过程中用小尺寸 loading 替代图标，避免重复点击。
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
                  width: 11,
                  height: 11,
                ),
                const SizedBox(width: 4),
                Text(
                  '订单.上传文件'.tr(),
                  style: TestStyle.pingFangRegular(
                    fontSize: 14,
                    color: const Color(0xFF171A1D),
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
        style: TestStyle.regular(fontSize: 14, color: const Color(0xFF8C8C8C)),
      ),
    );
  }
}

class _RejectReasonBottomSheet extends StatefulWidget {
  const _RejectReasonBottomSheet({
    required this.materials,
    required this.onClose,
  });

  final List<MaterialVO> materials;
  final VoidCallback onClose;

  @override
  State<_RejectReasonBottomSheet> createState() =>
      _RejectReasonBottomSheetState();
}

class _RejectReasonBottomSheetState extends State<_RejectReasonBottomSheet> {
  static const int _maxReasonLength = 50;

  late final List<_RejectReasonDraftItem> _draftItems;

  @override
  void initState() {
    super.initState();
    _draftItems = widget.materials
        .map(
          (MaterialVO material) => _RejectReasonDraftItem(
            material: material,
            controller: TextEditingController(
              text: _truncateReason((material.rejectReason ?? '').trim()),
            ),
          ),
        )
        .toList(growable: false);
  }

  @override
  void dispose() {
    for (final _RejectReasonDraftItem item in _draftItems) {
      item.dispose();
    }
    super.dispose();
  }

  String _truncateReason(String value) {
    if (value.length <= _maxReasonLength) {
      return value;
    }
    return value.substring(0, _maxReasonLength);
  }

  bool get _hasAnyReason =>
      _draftItems.any((item) => item.controller.text.trim().isNotEmpty);

  void _handleConfirm() {
    if (!_hasAnyReason) {
      AppToast.show('至少选择一项填写');
      return;
    }
    final List<OrderMaterialRejectionBO> materialRejections =
        <OrderMaterialRejectionBO>[];
    for (final _RejectReasonDraftItem item in _draftItems) {
      final String reason = item.controller.text.trim();
      if (reason.isEmpty) {
        continue;
      }
      materialRejections.add(
        OrderMaterialRejectionBO(
          materialId: item.material.materialId,
          reason: reason,
        ),
      );
    }
    Navigator.of(
      context,
    ).pop(_RejectReasonSubmitResult(materialRejections: materialRejections));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double maxSheetHeight = screenHeight * 0.7;

    return TapBlankToDismissKeyboard(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxSheetHeight),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Column(
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
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF4FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 9, 12, 9),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Color(0xFF096DD9),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '至少填写一项驳回原因，客户将收到通知并重新上传材料',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF096DD9),
                                fontSize: 12,
                                height: 18 / 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Flexible(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: _draftItems.length,
                      itemBuilder: (BuildContext context, int index) {
                        final _RejectReasonDraftItem item = _draftItems[index];
                        return Padding(
                          key: ValueKey<int>(item.material.materialId),
                          padding: EdgeInsets.only(
                            bottom: index == _draftItems.length - 1 ? 0 : 20,
                          ),
                          child: _RejectReasonMaterialCard(
                            materialName: _orderMaterialDisplayName(
                              item.material,
                            ),
                            controller: item.controller,
                            maxLength: _maxReasonLength,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
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
    );
  }
}

class _RejectReasonMaterialCard extends StatelessWidget {
  const _RejectReasonMaterialCard({
    required this.materialName,
    required this.controller,
    required this.maxLength,
  });

  final String materialName;
  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int currentLength = controller.text.characters.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            materialName,
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF333333),
              fontSize: 16,
              height: 22 / 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            children: <Widget>[
              TextField(
                controller: controller,
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
                  hintText: '例如：证件首页照片反光…',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF8C8C8C),
                    fontSize: 14,
                    height: 24 / 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$currentLength/$maxLength',
                  style: theme.textTheme.bodySmall?.copyWith(
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
      ],
    );
  }
}

class _RejectReasonSubmitResult {
  const _RejectReasonSubmitResult({required this.materialRejections});

  final List<OrderMaterialRejectionBO> materialRejections;
}

class _RejectReasonDraftItem {
  const _RejectReasonDraftItem({
    required this.material,
    required this.controller,
  });

  final MaterialVO material;
  final TextEditingController controller;

  void dispose() {
    controller.dispose();
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
          style: TestStyle.regular(fontSize: 16, color: foregroundColor),
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
              style: TestStyle.regular(
                fontSize: 13,
                color: const Color(0xFF595959),
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
              style: TestStyle.regular(
                fontSize: 14,
                color: const Color(0xFF595959),
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
              style: TestStyle.pingFangRegular(
                fontSize: 16,
                color: const Color(0xFF8C8C8C),
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
                        style: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: Color(0xFFD9363E),
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
                        style: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: Colors.white,
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
    this.exampleFileUrls = const <String>[],
  });

  final String id;
  final String title;
  final bool required;
  final List<String> exampleFileUrls;
}
