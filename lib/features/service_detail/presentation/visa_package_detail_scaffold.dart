import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import '../../../shared/widgets/app_toast.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/models/app_currency.dart';
import '../../../shared/network/api_error_feedback.dart';
import '../../config/data/config_models.dart';
import '../../config/data/config_providers.dart';
import '../../home/data/home_providers.dart';
import '../../../shared/network/services/config_service.dart';
import '../../../shared/presentation/attachment_preview_page.dart';
import '../../../shared/ui/app_colors.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/sample_file_selection_dialog.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../message/application/chat/chat_page_args.dart';
import '../../me/data/collection_models.dart' show CollectionBO;
import '../../me/data/collection_providers.dart';
import '../../visa/data/provider_models.dart'
    hide MaterialVO, TierVO, VisaPackageVO;
import '../../visa/data/provider_providers.dart';
import '../../visa/data/visa_package_models.dart';
import '../../visa/data/visa_package_providers.dart';
import 'service_detail_bottom_sheets.dart';
import 'service_detail_merchant_tab.dart';
import 'service_detail_package_tab.dart';
import 'service_detail_report_page.dart';
import 'service_detail_review_tab.dart';
import 'service_detail_share_card.dart';

import 'package:europepass/shared/ui/test_style.dart';

enum VisaPackageDetailMode { normal, preview }

class VisaPackageDetailScaffoldArgs {
  const VisaPackageDetailScaffoldArgs({
    required this.packageId,
    this.providerId,
    this.initialIsCollected = false,
    this.mode = VisaPackageDetailMode.normal,
  });

  final int packageId;
  final int? providerId;
  final bool initialIsCollected;
  final VisaPackageDetailMode mode;
}

/// 签证套餐详情骨架：根据模式裁剪顶部/底部操作区。
class VisaPackageDetailScaffold extends ConsumerStatefulWidget {
  const VisaPackageDetailScaffold({super.key, required this.args});

  final VisaPackageDetailScaffoldArgs args;

  @override
  ConsumerState<VisaPackageDetailScaffold> createState() =>
      _VisaPackageDetailScaffoldState();
}

class _VisaPackageDetailScaffoldState
    extends ConsumerState<VisaPackageDetailScaffold> {
  static const double _expandedAppBarHeight = 292;
  static const String _heroAsset =
      'assets/images/service_detail_top_background.png';
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const String _favoriteAsset =
      'assets/images/service_detail_favorite.svg';
  static const String _favoriteFillAsset =
      'assets/images/service_detail_favorite_fill.svg';
  static const String _shareAsset = 'assets/images/service_detail_share.svg';
  static const String _verifiedBadgeAsset =
      'assets/images/service_detail_verified_badge.png';
  static const String _consultIconAsset =
      'assets/images/service_detail_consult_icon.svg';

  int _selectedPackageIndex = 0;
  VisaProviderReviewSort _selectedReviewSort = VisaProviderReviewSort.hot;
  ReviewVO? _cachedReview;
  int? _initialReviewTotalCount;
  int? _initialReviewTotalProviderId;
  bool _isCollecting = false;
  bool _showCollapsedTitle = false;
  bool? _isCollectedOverride;
  final Set<String> _downloadingMaterialUrls = <String>{};
  final ScreenshotController _shareScreenshotController =
      ScreenshotController();

  bool get _isPreviewMode => widget.args.mode == VisaPackageDetailMode.preview;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<VisaPackageVO> packageAsync = ref.watch(
      visaPackageDetailProvider(widget.args.packageId),
    );

    final bool isFavorited = _isCollected;

    return packageAsync.when(
      loading: () => const _ServiceDetailLoadingPage(),
      error: (Object error, StackTrace stackTrace) {
        return _ServiceDetailMessagePage(
          message: _resolveErrorMessage(error, fallback: '服务详情.套餐详情加载失败'.tr()),
        );
      },
      data: (VisaPackageVO package) {
        final int? effectiveProviderId =
            widget.args.providerId ??
            (package.providerId > 0 ? package.providerId : null);
        final AsyncValue<VisaProviderDetailVO>? providerDetailAsync =
            effectiveProviderId == null
            ? null
            : ref.watch(visaProviderDetailProvider(effectiveProviderId));
        final AsyncValue<ReviewVO>? reviewAsync = effectiveProviderId == null
            ? null
            : ref.watch(
                visaProviderReviewsProvider(
                  VisaProviderReviewsQuery(
                    providerId: effectiveProviderId,
                    sort: _selectedReviewSort,
                  ),
                ),
              );
        if (effectiveProviderId == null) {
          _cachedReview = null;
          _initialReviewTotalCount = null;
          _initialReviewTotalProviderId = null;
        } else if (reviewAsync?.asData?.value != null) {
          _cachedReview = reviewAsync!.asData!.value;
          if (_initialReviewTotalProviderId != effectiveProviderId) {
            _initialReviewTotalProviderId = effectiveProviderId;
            _initialReviewTotalCount =
                reviewAsync.asData!.value.summary.totalCount;
          } else {
            _initialReviewTotalCount ??=
                reviewAsync.asData!.value.summary.totalCount;
          }
        }
        final ReviewVO? effectiveReview =
            reviewAsync?.asData?.value ?? _cachedReview;
        final List<ServicePackageData> servicePackages = package
            .toServicePackages();
        final List<ServiceMaterialData> serviceMaterials = package
            .toServiceMaterials();
        final int selectedPackageIndex = _resolveSelectedPackageIndex(
          servicePackages.length,
        );
        final ServicePackageData? selectedPackage = servicePackages.isEmpty
            ? null
            : servicePackages[selectedPackageIndex];
        final ProviderVO? provider =
            providerDetailAsync?.asData?.value.provider;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: _isPreviewMode
                ? null
                : _BottomActionBar(
                    consultIconAsset: _consultIconAsset,
                    onReportTap: () {
                      if (provider == null || provider.providerId <= 0) {
                        AppToast.show('服务详情.暂无商家信息'.tr());
                        return;
                      }
                      context.push(
                        RoutePaths.serviceDetailReport,
                        extra: ServiceDetailReportPageArgs(
                          targetType: 'visa_provider',
                          targetId: provider.providerId,
                          targetName: provider.name,
                          initialTitle: provider.name.trim().isEmpty
                              ? ''
                              : '投诉.默认标题'.tr(
                                  namedArgs: <String, String>{
                                    'name': provider.name.trim(),
                                  },
                                ),
                        ),
                      );
                    },
                    onConsultTap: () => _handleConsultTap(provider),
                    onApplyTap: () => _showApplyBottomSheet(
                      serviceTitle: package.name,
                      package: selectedPackage,
                    ),
                  ),
            body: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification.depth != 0) {
                  return false;
                }
                final bool shouldShowTitle =
                    notification.metrics.pixels >=
                    _collapseThreshold(context: context);
                if (shouldShowTitle != _showCollapsedTitle) {
                  setState(() => _showCollapsedTitle = shouldShowTitle);
                }
                return false;
              },
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return <Widget>[
                    SliverAppBar(
                      pinned: true,
                      stretch: true,
                      expandedHeight: _expandedAppBarHeight,
                      backgroundColor: AppColors.surface,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      automaticallyImplyLeading: false,
                      titleSpacing: 70,
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _showCollapsedTitle ? 1 : 0,
                        child: Text(
                          '服务详情.标题'.tr(),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF262626),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final double topPadding = MediaQuery.paddingOf(
                            context,
                          ).top;
                          final bool collapsed = _isCollapsed(
                            constraints.biggest.height,
                            topPadding,
                          );
                          final double progress = _collapseProgress(
                            constraints.biggest.height,
                            topPadding,
                          );

                          return _SliverHeroAppBar(
                            imageUrl: package.coverImages.isEmpty
                                ? ''
                                : package.coverImages.first,
                            backAsset: _backAsset,
                            favoriteAsset: _favoriteAsset,
                            favoriteFillAsset: _favoriteFillAsset,
                            shareAsset: _shareAsset,
                            collapsed: collapsed,
                            progress: progress,
                            showFavoriteAction: !_isPreviewMode,
                            isFavorited: isFavorited,
                            onBackTap: () {
                              if (Navigator.of(context).canPop()) {
                                context.pop();
                              }
                            },
                            onFavoriteTap: _toggleCollection,
                            onShareTap: () {
                              _shareServiceDetail(
                                package: package,
                                provider: provider,
                                selectedPackage: selectedPackage,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SummaryPanel(
                        serviceTitle: package.name,
                        selectedPackage: selectedPackage,
                        packageDetail: package,
                        provider: provider,
                        verifiedBadgeAsset: _verifiedBadgeAsset,
                      ),
                    ),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _PinnedTopTabBarDelegate(
                        child: _ServiceDetailTabBar(
                          reviewCount: _initialReviewTotalCount,
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: <Widget>[
                    ServiceDetailPackageTab(
                      packages: servicePackages,
                      selectedPackageIndex: selectedPackageIndex,
                      onPackageSelected: (int index) {
                        setState(() => _selectedPackageIndex = index);
                      },
                      materials: serviceMaterials,
                      downloadingFileUrls: _downloadingMaterialUrls,
                      onMaterialTap: _downloadAndOpenMaterial,
                      onPreviewTap: () =>
                          _showSampleFilesDialog(serviceMaterials),
                    ),
                    ServiceDetailReviewTab(
                      review: effectiveReview,
                      isLoading: reviewAsync?.isLoading ?? false,
                      selectedSort: _selectedReviewSort,
                      onSortChanged: (VisaProviderReviewSort sort) {
                        if (_selectedReviewSort == sort) {
                          return;
                        }
                        setState(() {
                          _selectedReviewSort = sort;
                        });
                      },
                      errorMessage: effectiveProviderId == null
                          ? '服务详情.暂无评价数据'.tr()
                          : effectiveReview != null
                          ? null
                          : _resolveAsyncErrorMessage(
                              reviewAsync,
                              fallback: '服务详情.评价加载失败'.tr(),
                            ),
                    ),
                    ServiceDetailMerchantTab(
                      verifiedBadgeAsset: _verifiedBadgeAsset,
                      provider: provider,
                      isLoading: providerDetailAsync?.isLoading ?? false,
                      errorMessage: effectiveProviderId == null
                          ? '服务详情.暂无商家信息'.tr()
                          : _resolveAsyncErrorMessage(
                              providerDetailAsync,
                              fallback: '服务详情.商家信息加载失败'.tr(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 当前收藏状态，优先采用本地交互后的覆盖值。
  bool get _isCollected =>
      _isCollectedOverride ?? widget.args.initialIsCollected;

  /// 计算头图折叠阈值，统一控制标题显隐。
  double _collapseThreshold({required BuildContext context}) {
    return _expandedAppBarHeight -
        (kToolbarHeight + MediaQuery.paddingOf(context).top) -
        12;
  }

  /// 解析当前有效的档位索引，避免空数组或索引越界。
  int _resolveSelectedPackageIndex(int packageCount) {
    if (packageCount <= 0) {
      return 0;
    }
    if (_selectedPackageIndex < 0) {
      return 0;
    }
    if (_selectedPackageIndex >= packageCount) {
      return packageCount - 1;
    }
    return _selectedPackageIndex;
  }

  /// 判断头图是否已经进入折叠态。
  bool _isCollapsed(double currentHeight, double topPadding) {
    final double minExtent = kToolbarHeight + topPadding;
    return currentHeight <= minExtent + 12;
  }

  /// 计算头图从展开到折叠的过渡进度。
  double _collapseProgress(double currentHeight, double topPadding) {
    final double minExtent = kToolbarHeight + topPadding;
    final double delta = (_expandedAppBarHeight - minExtent).clamp(
      1,
      double.infinity,
    );
    return ((_expandedAppBarHeight - currentHeight) / delta).clamp(0.0, 1.0);
  }

  /// 打开申请弹窗，若没有可选档位则提示用户。
  void _showApplyBottomSheet({
    required String serviceTitle,
    required ServicePackageData? package,
  }) {
    if (package == null) {
      AppToast.show('服务详情.当前套餐暂无可申请档位'.tr());
      return;
    }
    ServiceDetailApplyBottomSheet.show(
      context: context,
      serviceTitle: serviceTitle,
      package: package,
    );
  }

  /// 跳转到聊天页，并携带当前服务商作为聊天对象。
  void _handleConsultTap(ProviderVO? provider) {
    if (provider == null) {
      _showMessage('服务详情.商家信息加载中'.tr());
      return;
    }
    if (provider.providerId <= 0) {
      _showMessage('服务详情.商家信息缺失'.tr());
      return;
    }
    context.push(
      RoutePaths.chat,
      extra: ChatPageArgs(
        targetUserId: provider.providerId,
        targetUserRole: 'visa_provider',
        nickname: provider.name.trim().isEmpty
            ? '服务详情.服务商'.tr()
            : provider.name,
        avatarUrl: provider.logoUrl,
      ),
    );
  }

  /// 切换签证详情收藏状态，并同步调用真实收藏接口。
  Future<void> _toggleCollection() async {
    final int packageId = widget.args.packageId;
    if (_isPreviewMode || _isCollecting || packageId <= 0) {
      return;
    }

    setState(() {
      _isCollecting = true;
    });

    final bool wasCollected = _isCollected;

    try {
      final service = ref.read(collectionServiceProvider);
      final request = CollectionBO(
        targetType: 'visa_package',
        targetId: packageId,
      );
      if (wasCollected) {
        await service.removeCollection(request: request);
      } else {
        await service.addCollection(request: request);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isCollecting = false;
        _isCollectedOverride = !wasCollected;
      });
      ref.invalidate(homeDashboardStatsProvider);
      ref.read(collectionRefreshTickProvider.notifier).bump();
      _showMessage(wasCollected ? '服务详情.已取消收藏'.tr() : '服务详情.收藏成功'.tr());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCollecting = false;
      });
      final String? toastMessage = ApiErrorFeedback.toastMessage(error);
      if (toastMessage != null) {
        _showMessage(toastMessage);
      } else if (!ApiErrorFeedback.hasAutoToast(error)) {
        _showMessage(_resolveErrorMessage(error, fallback: '服务详情.收藏操作失败'.tr()));
      }
    }
  }

  /// 统一展示签证详情页的提示消息。
  void _showMessage(String message) {
    AppToast.show(message);
  }

  Future<void> _shareServiceDetail({
    required VisaPackageVO package,
    required ProviderVO? provider,
    required ServicePackageData? selectedPackage,
  }) async {
    final String title = _shareTitle(package);
    final RenderBox? box = context.findRenderObject() as RenderBox?;

    try {
      final File imageFile = await _captureShareImage(
        package: package,
        provider: provider,
        selectedPackage: selectedPackage,
      );
      await SharePlus.instance.share(
        ShareParams(
          title: title,
          subject: title,
          files: <XFile>[XFile(imageFile.path)],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      try {
        await _shareServiceDetailText(
          package: package,
          provider: provider,
          selectedPackage: selectedPackage,
        );
      } catch (_) {
        if (!mounted) {
          return;
        }
        _showMessage('服务详情.分享失败'.tr());
      }
    }
  }

  Future<File> _captureShareImage({
    required VisaPackageVO package,
    required ProviderVO? provider,
    required ServicePackageData? selectedPackage,
  }) async {
    final List<ServicePackageData> servicePackages = package
        .toServicePackages();
    final List<ServiceMaterialData> serviceMaterials = package
        .toServiceMaterials();
    final int selectedPackageIndex = selectedPackage == null
        ? _resolveSelectedPackageIndex(servicePackages.length)
        : servicePackages.indexWhere(
            (ServicePackageData item) => item.tierId == selectedPackage.tierId,
          );
    final Uint8List imageBytes = await _shareScreenshotController
        .captureFromLongWidget(
          InheritedTheme.captureAll(
            context,
            Material(
              color: const Color(0xFFF5F7FA),
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: _buildShareCard(
                    package: package,
                    provider: provider,
                    packages: servicePackages,
                    selectedPackageIndex: selectedPackageIndex < 0
                        ? _resolveSelectedPackageIndex(servicePackages.length)
                        : selectedPackageIndex,
                    materials: serviceMaterials,
                  ),
                ),
              ),
            ),
          ),
          context: context,
          constraints: const BoxConstraints(
            maxWidth: ServiceDetailShareCard.shareWidth,
          ),
          pixelRatio: MediaQuery.devicePixelRatioOf(context),
          delay: const Duration(milliseconds: 300),
        );
    if (imageBytes.isEmpty) {
      throw Exception('service_detail_share_image_empty');
    }
    final Directory tempDirectory = await getTemporaryDirectory();
    final Directory shareDirectory = Directory(
      '${tempDirectory.path}/service_detail_share',
    );
    if (!shareDirectory.existsSync()) {
      await shareDirectory.create(recursive: true);
    }
    final File imageFile = File(
      '${shareDirectory.path}/service_detail_share_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await imageFile.writeAsBytes(imageBytes, flush: true);
    return imageFile;
  }

  Widget _buildShareCard({
    required VisaPackageVO package,
    required ProviderVO? provider,
    required List<ServicePackageData> packages,
    required int selectedPackageIndex,
    required List<ServiceMaterialData> materials,
  }) {
    return ServiceDetailShareCard(
      package: package,
      provider: provider,
      packages: packages,
      selectedPackageIndex: selectedPackageIndex,
      materials: materials,
      verifiedBadgeAsset: _verifiedBadgeAsset,
      serviceTagLabelMap: _buildServiceTagLabelMap(),
    );
  }

  Map<String, String> _buildServiceTagLabelMap() {
    final List<TagItemVO> serviceTags =
        ref.read(tagDictionaryProvider(TagCategory.service)).asData?.value ??
        const <TagItemVO>[];
    final bool isChineseLocale = context.locale.languageCode
        .toLowerCase()
        .startsWith('zh');
    return <String, String>{
      for (final TagItemVO item in serviceTags)
        item.tagCode.trim(): isChineseLocale
            ? _resolveZhFirstTagLabel(item)
            : _resolveEnFirstTagLabel(item),
    };
  }

  String _resolveZhFirstTagLabel(TagItemVO item) {
    final String zh = item.tagNameZh.trim();
    if (zh.isNotEmpty) {
      return zh;
    }
    final String en = item.tagNameEn.trim();
    return en.isNotEmpty ? en : item.tagCode.trim();
  }

  String _resolveEnFirstTagLabel(TagItemVO item) {
    final String en = item.tagNameEn.trim();
    if (en.isNotEmpty) {
      return en;
    }
    final String zh = item.tagNameZh.trim();
    return zh.isNotEmpty ? zh : item.tagCode.trim();
  }

  Future<void> _shareServiceDetailText({
    required VisaPackageVO package,
    required ProviderVO? provider,
    required ServicePackageData? selectedPackage,
  }) async {
    final String title = _shareTitle(package);
    final List<String> lines = <String>[
      title,
      if (provider != null && provider.name.trim().isNotEmpty)
        '服务详情.分享商家'.tr(
          namedArgs: <String, String>{'merchant': provider.name.trim()},
        ),
      if (selectedPackage != null && selectedPackage.title.trim().isNotEmpty)
        '服务详情.分享套餐'.tr(
          namedArgs: <String, String>{'package': selectedPackage.title.trim()},
        ),
      if (package.estimatedDays > 0)
        '服务详情.预计办理天数'.tr(
          namedArgs: <String, String>{'days': package.estimatedDays.toString()},
        ),
      if (provider != null && provider.brief.trim().isNotEmpty)
        provider.brief.trim(),
    ];
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: lines.join('\n'),
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  String _shareTitle(VisaPackageVO package) {
    return package.name.trim().isEmpty ? '服务详情.标题'.tr() : package.name.trim();
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
    throw Exception('服务详情.下载目录无访问权限'.tr());
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

  String _materialDisplayName(ServiceMaterialData material) {
    final String materialName = material.title.trim();
    if (materialName.isNotEmpty) {
      return materialName;
    }
    final Uri? uri = Uri.tryParse(material.fileUrl);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return Uri.decodeComponent(uri.pathSegments.last);
    }
    return '服务详情.所需材料'.tr();
  }

  String _materialFileExtension(ServiceMaterialData material) {
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

    return '';
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  List<_ServiceSampleFileData> _buildSampleFiles(
    List<ServiceMaterialData> materials,
  ) {
    final Set<String> uniqueUrls = <String>{};
    final List<_ServiceSampleFileData> files = <_ServiceSampleFileData>[];
    for (final ServiceMaterialData material in materials) {
      for (final String rawUrl in material.exampleFileUrls) {
        final String fileUrl = rawUrl.trim();
        if (fileUrl.isEmpty || !uniqueUrls.add(fileUrl)) {
          continue;
        }
        final Uri? uri = Uri.tryParse(fileUrl);
        final String fileName = uri != null && uri.pathSegments.isNotEmpty
            ? Uri.decodeComponent(uri.pathSegments.last)
            : material.title;
        files.add(
          _ServiceSampleFileData(
            title: fileName.trim().isEmpty ? material.title : fileName,
            subtitle: material.title.trim().isEmpty
                ? '服务详情.所需材料'.tr()
                : material.title,
            fileUrl: fileUrl,
          ),
        );
      }
    }
    return files;
  }

  Future<void> _showSampleFilesDialog(
    List<ServiceMaterialData> materials,
  ) async {
    final List<_ServiceSampleFileData> sampleFiles = _buildSampleFiles(
      materials,
    );
    if (sampleFiles.isEmpty) {
      _showMessage('服务详情.文件地址不存在'.tr());
      return;
    }
    if (!mounted) {
      return;
    }

    await showAppDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return SampleFileSelectionDialog(
          title: '服务详情.查看样例'.tr(),
          itemCount: sampleFiles.length,
          itemBuilder: (BuildContext context, int index) {
            final _ServiceSampleFileData file = sampleFiles[index];
            final ServiceMaterialData material = ServiceMaterialData(
              title: file.title,
              subtitle: file.subtitle,
              status: '服务详情.查看样例'.tr(),
              required: false,
              description: file.subtitle,
              exampleFileUrls: <String>[file.fileUrl],
            );
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == sampleFiles.length - 1 ? 0 : 12,
              ),
              child: _ServiceSampleFileCard(
                material: material,
                isDownloading: _downloadingMaterialUrls.contains(file.fileUrl),
                onPreviewTap: () async {
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                  await _previewSampleFile(file);
                },
                onDownloadTap: () => _downloadAndOpenSampleFile(file),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _downloadAndOpenSampleFile(_ServiceSampleFileData file) async {
    final ServiceMaterialData material = ServiceMaterialData(
      title: file.title,
      subtitle: file.subtitle,
      status: '服务详情.查看样例'.tr(),
      required: false,
      description: file.subtitle,
      exampleFileUrls: <String>[file.fileUrl],
    );
    await _downloadAndOpenMaterial(material);
  }

  /// 使用页面上下文打开样例附件预览，避免在弹窗子上下文里直接做路由跳转。
  Future<void> _previewSampleFile(_ServiceSampleFileData file) async {
    final String fileUrl = file.fileUrl.trim();
    if (fileUrl.isEmpty) {
      _showMessage('服务详情.文件地址不存在'.tr());
      return;
    }
    await openAttachmentPreview(
      context,
      path: fileUrl,
      title: file.title,
      isImage: UploadPickerUtils.isImagePath(fileUrl),
      isPdf:
          UploadPickerUtils.isPdfPath(fileUrl) ||
          UploadPickerUtils.isPdfPath(file.title),
    );
  }

  Future<void> _downloadAndOpenMaterial(ServiceMaterialData material) async {
    final String fileUrl = material.fileUrl.trim();
    if (fileUrl.isEmpty) {
      _showMessage('服务详情.文件地址不存在'.tr());
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

      final OpenResult openResult = await OpenFilex.open(savePath);
      if (openResult.type != ResultType.done) {
        final String message = openResult.message.trim();
        _showMessage(message.isEmpty ? '服务详情.文件打开失败'.tr() : message);
      }
    } on DioException {
      if (!mounted) {
        return;
      }
      _showMessage('服务详情.文件下载失败'.tr());
    } catch (error) {
      if (!mounted) {
        return;
      }
      final String? toastMessage = ApiErrorFeedback.toastMessage(error);
      if (toastMessage != null) {
        _showMessage(toastMessage);
      } else if (!ApiErrorFeedback.hasAutoToast(error)) {
        _showMessage(_resolveErrorMessage(error, fallback: '服务详情.文件下载失败'.tr()));
      }
    } finally {
      dio.close(force: true);
      if (mounted) {
        setState(() {
          _downloadingMaterialUrls.remove(fileUrl);
        });
      }
    }
  }
}

class _ServiceDetailLoadingPage extends StatelessWidget {
  const _ServiceDetailLoadingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ServiceSampleFileData {
  const _ServiceSampleFileData({
    required this.title,
    required this.subtitle,
    required this.fileUrl,
  });

  final String title;
  final String subtitle;
  final String fileUrl;
}

class _ServiceSampleFileCard extends StatelessWidget {
  const _ServiceSampleFileCard({
    required this.material,
    required this.isDownloading,
    required this.onPreviewTap,
    required this.onDownloadTap,
  });

  final ServiceMaterialData material;
  final bool isDownloading;
  final VoidCallback onPreviewTap;
  final VoidCallback onDownloadTap;

  @override
  Widget build(BuildContext context) {
    return SampleFileSelectionItem(
      title: material.title,
      subtitle: material.subtitle,
      fileUrl: material.fileUrl,
      onTap: onPreviewTap,
      isDownloading: isDownloading,
      onDownloadTap: onDownloadTap,
    );
  }
}

class _ServiceDetailMessagePage extends StatelessWidget {
  const _ServiceDetailMessagePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text('服务详情.标题'.tr()),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8C8C8C)),
          ),
        ),
      ),
    );
  }
}

class _SliverHeroAppBar extends StatelessWidget {
  const _SliverHeroAppBar({
    required this.imageUrl,
    required this.backAsset,
    required this.favoriteAsset,
    required this.favoriteFillAsset,
    required this.shareAsset,
    required this.collapsed,
    required this.progress,
    this.showFavoriteAction = true,
    required this.isFavorited,
    required this.onBackTap,
    required this.onFavoriteTap,
    required this.onShareTap,
  });

  final String imageUrl;
  final String backAsset;
  final String favoriteAsset;
  final String favoriteFillAsset;
  final String shareAsset;
  final bool collapsed;
  final double progress;
  final bool showFavoriteAction;
  final bool isFavorited;
  final VoidCallback onBackTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = Color.lerp(
      Colors.white,
      const Color(0xFF262626),
      progress,
    )!;
    final Color buttonBackground = Color.lerp(
      Colors.black.withValues(alpha: 0.28),
      AppColors.surface.withValues(alpha: 0.92),
      progress,
    )!;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        _HeroBackground(imageUrl: imageUrl),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            height: 18,
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Colors.black.withValues(alpha: 0.18 * (1 - progress)),
                Colors.black.withValues(alpha: 0.06 * (1 - progress)),
                Colors.transparent,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: progress),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _TopCircleAction(
                    assetPath: backAsset,
                    fallback: Icons.arrow_back_ios_new_rounded,
                    color: iconColor,
                    backgroundColor: buttonBackground,
                    onTap: onBackTap,
                  ),
                  const Spacer(),
                  if (showFavoriteAction) ...<Widget>[
                    _TopCircleAction(
                      assetPath: isFavorited
                          ? favoriteFillAsset
                          : favoriteAsset,
                      fallback: isFavorited
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: isFavorited && collapsed
                          ? AppColors.warning
                          : isFavorited
                          ? const Color(0xFFFFD166)
                          : iconColor,
                      backgroundColor: buttonBackground,
                      onTap: onFavoriteTap,
                    ),
                    const SizedBox(width: 12),
                  ],
                  _TopCircleAction(
                    assetPath: shareAsset,
                    fallback: Icons.share_outlined,
                    color: iconColor,
                    backgroundColor: buttonBackground,
                    onTap: onShareTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return Image.asset(
        _VisaPackageDetailScaffoldState._heroAsset,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) {
        return Image.asset(
          _VisaPackageDetailScaffoldState._heroAsset,
          fit: BoxFit.cover,
        );
      },
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.serviceTitle,
    required this.selectedPackage,
    required this.packageDetail,
    required this.provider,
    required this.verifiedBadgeAsset,
  });

  final String serviceTitle;
  final ServicePackageData? selectedPackage;
  final VisaPackageVO packageDetail;
  final ProviderVO? provider;
  final String verifiedBadgeAsset;

  @override
  Widget build(BuildContext context) {
    final String summaryDescription = provider?.brief.trim().isNotEmpty == true
        ? provider!.brief
        : '服务详情.预计办理天数'.tr(
            namedArgs: <String, String>{
              'days': packageDetail.estimatedDays > 0
                  ? packageDetail.estimatedDays.toString()
                  : '--',
            },
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  serviceTitle,
                  style: TestStyle.numberBold(
                    fontSize: 22,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: <InlineSpan>[
                    TextSpan(
                      text:
                          selectedPackage?.price ??
                          _formatPrice(0, packageDetail.currency),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFFFE5815),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    TextSpan(
                      text: '服务详情.起'.tr(),
                      style: TestStyle.pingFangSemibold(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              if (provider?.isVerified == true)
                Image.asset(
                  verifiedBadgeAsset,
                  width: 55.67,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              _SummaryTag(
                label: _formatCountryLabel(packageDetail.targetCountry),
              ),
              _SummaryTag(label: _formatVisaTypeLabel(packageDetail.visaType)),
              if (packageDetail.estimatedDays > 0)
                _SummaryTag(
                  label: '服务详情.天办结'.tr(
                    namedArgs: <String, String>{
                      'days': packageDetail.estimatedDays.toString(),
                    },
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summaryDescription,
            style: TestStyle.regular(
              fontSize: 12,
              color: const Color(0xFF595959),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceDetailTabBar extends StatelessWidget {
  const _ServiceDetailTabBar({this.reviewCount});

  final int? reviewCount;

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: controller,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelPadding: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        indicatorPadding: EdgeInsets.zero,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        dividerColor: Colors.transparent,
        indicator: const _FixedWidthUnderlineIndicator(
          width: 20,
          bottomOffset: 2,
          borderSide: BorderSide(color: Color(0xFF096DD9), width: 2),
        ),
        tabs: <Widget>[
          _ServiceDetailTab(
            label: '服务详情.套餐'.tr(),
            selectedWeight: FontWeight.w500,
            horizontalPadding: const EdgeInsets.only(left: 16, right: 16),
          ),
          _ServiceDetailTab(
            label: '服务详情.评价'.tr(),
            reviewCount: reviewCount,
            horizontalPadding: const EdgeInsets.only(left: 16, right: 16),
          ),
          _ServiceDetailTab(label: '服务详情.商家'.tr()),
        ],
      ),
    );
  }
}

class _ServiceDetailTab extends StatelessWidget {
  const _ServiceDetailTab({
    required this.label,
    this.reviewCount,
    this.selectedWeight = FontWeight.w500,
    this.horizontalPadding = EdgeInsets.zero,
  });

  final String label;
  final int? reviewCount;
  final FontWeight selectedWeight;
  final EdgeInsets horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final int tabIndex = <String>[
          '服务详情.套餐'.tr(),
          '服务详情.评价'.tr(),
          '服务详情.商家'.tr(),
        ].indexOf(label);
        final bool selected = controller.index == tabIndex;
        final TextStyle? labelStyle = Theme.of(context).textTheme.titleMedium
            ?.copyWith(
              color: const Color(0xFF262626),
              fontSize: 16,
              height: 1.2,
              fontWeight: selected ? selectedWeight : FontWeight.w400,
            );
        final bool showReviewCount = tabIndex == 1 && reviewCount != null;
        final String reviewCountText = showReviewCount
            ? _formatReviewTabCount(reviewCount!)
            : '';
        final double labelWidth = _measureTextWidth(
          context: context,
          text: label,
          style: labelStyle,
        );

        return Tab(
          height: 48,
          child: Container(
            width: showReviewCount ? 72 : 60,
            alignment: Alignment.center,
            child: SizedBox(
              width: 60,
              height: 24,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Align(
                    alignment: Alignment.center,
                    child: Text(label, style: labelStyle),
                  ),
                  if (showReviewCount)
                    Positioned(
                      left: 30 + (labelWidth / 2),
                      top: 1,
                      child: Text(
                        reviewCountText,
                        style: TestStyle.regular(
                          fontSize: 10,
                          color: const Color(0xFF8C8C8C),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double _measureTextWidth({
  required BuildContext context,
  required String text,
  required TextStyle? style,
}) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return textPainter.width;
}

String _formatReviewTabCount(int count) {
  if (count > 999) {
    return '999+';
  }
  return count.toString();
}

class _FixedWidthUnderlineIndicator extends Decoration {
  const _FixedWidthUnderlineIndicator({
    required this.width,
    this.bottomOffset = 0,
    required this.borderSide,
  });

  final double width;
  final double bottomOffset;
  final BorderSide borderSide;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FixedWidthUnderlinePainter(
      width: width,
      bottomOffset: bottomOffset,
      borderSide: borderSide,
    );
  }
}

class _FixedWidthUnderlinePainter extends BoxPainter {
  const _FixedWidthUnderlinePainter({
    required this.width,
    required this.bottomOffset,
    required this.borderSide,
  });

  final double width;
  final double bottomOffset;
  final BorderSide borderSide;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size? size = configuration.size;
    if (size == null) {
      return;
    }
    final Paint paint = borderSide.toPaint();
    final double y = offset.dy + size.height - borderSide.width - bottomOffset;
    final double x = offset.dx + (size.width - width) / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, borderSide.width),
        const Radius.circular(2),
      ),
      paint,
    );
  }
}

class _PinnedTopTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedTopTabBarDelegate({required this.child});

  final Widget child;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: overlapsContent
            ? <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : const <BoxShadow>[],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTopTabBarDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.consultIconAsset,
    required this.onReportTap,
    required this.onConsultTap,
    required this.onApplyTap,
  });

  final String consultIconAsset;
  final VoidCallback onReportTap;
  final VoidCallback onConsultTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    final TabController controller = DefaultTabController.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        switch (controller.index) {
          case 1:
            return const SizedBox.shrink();
          case 2:
            return _MerchantBottomActionBar(
              onReportTap: onReportTap,
              onConsultTap: onConsultTap,
            );
          case 0:
          default:
            return _PackageBottomActionBar(
              consultIconAsset: consultIconAsset,
              onConsultTap: onConsultTap,
              onApplyTap: onApplyTap,
            );
        }
      },
    );
  }
}

class _PackageBottomActionBar extends StatelessWidget {
  const _PackageBottomActionBar({
    required this.consultIconAsset,
    required this.onConsultTap,
    required this.onApplyTap,
  });

  final String consultIconAsset;
  final VoidCallback onConsultTap;
  final VoidCallback onApplyTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 48,
              height: 44,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onConsultTap,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      top: 1,
                      left: 12,
                      width: 24,
                      height: 24,
                      child: AppSvgIcon(
                        assetPath: consultIconAsset,
                        fallback: Icons.headset_mic_outlined,
                        size: 24,
                        color: const Color(0xFF8C8C8C),
                      ),
                    ),
                    Positioned(
                      top: 27,
                      left: 3,
                      right: 3,
                      child: Text(
                        '服务详情.咨询'.tr(),
                        textAlign: TextAlign.center,
                        style: TestStyle.pingFangMedium(
                          fontSize: 10,
                          color: const Color(0xFF8C8C8C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: onApplyTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  '服务详情.立即申请'.tr(),
                  style: TestStyle.numberBold(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MerchantBottomActionBar extends StatelessWidget {
  const _MerchantBottomActionBar({
    required this.onReportTap,
    required this.onConsultTap,
  });

  final VoidCallback onReportTap;
  final VoidCallback onConsultTap;

  @override
  Widget build(BuildContext context) {
    final TextStyle? secondaryStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(
          color: const Color(0xFF171A1D),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 22 / 16,
        );
    final TextStyle? primaryStyle = Theme.of(context).textTheme.titleMedium
        ?.copyWith(
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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 169,
              child: OutlinedButton(
                onPressed: onReportTap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Color(0xFFD9D9D9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text('服务详情.举报商家'.tr(), style: secondaryStyle),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 170,
              child: FilledButton(
                onPressed: onConsultTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text('服务详情.联系商家'.tr(), style: primaryStyle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleAction extends StatelessWidget {
  const _TopCircleAction({
    required this.assetPath,
    required this.fallback,
    required this.onTap,
    this.color = Colors.white,
    this.backgroundColor = const Color(0x47000000),
  });

  final String assetPath;
  final IconData fallback;
  final VoidCallback onTap;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: AppSvgIcon(
                  assetPath: assetPath,
                  fallback: fallback,
                  size: 18,
                  color: color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryTag extends StatelessWidget {
  const _SummaryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TestStyle.numberBold(
          fontSize: 11,
          color: const Color(0xFF386EF8),
        ),
      ),
    );
  }
}

/// 提取异步 Provider 的错误文案，优先透传后端提示。
String? _resolveAsyncErrorMessage<T>(
  AsyncValue<T>? asyncValue, {
  required String fallback,
}) {
  final Object? error = asyncValue?.asError?.error;
  if (error == null) {
    return null;
  }
  return _resolveErrorMessage(error, fallback: fallback);
}

/// 统一处理接口异常文案。
String _resolveErrorMessage(Object error, {required String fallback}) {
  return ApiErrorFeedback.resolveMessage(error, fallback: fallback);
}

/// 将签证套餐详情映射为详情页的档位和材料展示模型。
extension on VisaPackageVO {
  List<ServicePackageData> toServicePackages() {
    return tiers
        .map(
          (TierVO tier) => ServicePackageData(
            packageId: packageId,
            tierId: tier.tierId,
            title: tier.name.trim().isEmpty ? '服务详情.套餐档位'.tr() : tier.name,
            amount: tier.price,
            currency: currency,
            price: _formatPrice(tier.price, currency),
            description: tier.description.trim().isEmpty
                ? '服务详情.暂无套餐说明'.tr()
                : tier.description,
            tags: tier.services.isEmpty
                ? <String>['服务详情.暂无服务标签'.tr()]
                : tier.services,
          ),
        )
        .toList(growable: false);
  }

  List<ServiceMaterialData> toServiceMaterials() {
    return requiredMaterials
        .map(
          (PackageMaterialVO material) => ServiceMaterialData(
            title: material.name.trim().isEmpty
                ? '服务详情.所需材料'.tr()
                : material.name,
            subtitle: _buildMaterialSubtitle(material),
            status: _buildMaterialStatus(material),
            required: material.isRequired,
            description: material.description,
            exampleFileUrls: material.exampleFileUrls,
          ),
        )
        .toList(growable: false);
  }
}

/// 组装材料副标题，优先展示材料说明，其次回退为示例文件数量。
String _buildMaterialSubtitle(PackageMaterialVO material) {
  if (material.description.trim().isNotEmpty) {
    return material.description;
  }
  final int sampleCount = material.exampleFileUrls.length;
  if (sampleCount > 0) {
    return '服务详情.已提供示例文件'.tr(
      namedArgs: <String, String>{'count': sampleCount.toString()},
    );
  }
  return '服务详情.请按服务要求准备相关材料'.tr();
}

/// 组装材料状态文案，优先展示必填/选填。
String _buildMaterialStatus(PackageMaterialVO material) {
  if (material.isRequired) {
    return '服务详情.必填'.tr();
  }
  return material.exampleFileUrls.isEmpty ? '服务详情.材料'.tr() : '服务详情.查看样例'.tr();
}

/// 格式化详情页价格，统一复用币种前缀转换规则。
String _formatPrice(double amount, String currency) {
  return AppCurrency.formatAmount(amount, currency);
}

/// 将国家代码转为详情页展示文案。
String _formatCountryLabel(String country) {
  return switch (country.trim().toUpperCase()) {
    'DE' => '国家.德国'.tr(),
    'FR' => '国家.法国'.tr(),
    'IT' => '国家.意大利'.tr(),
    'ES' => '国家.西班牙'.tr(),
    'NL' => '国家.荷兰'.tr(),
    'BE' => '国家.比利时'.tr(),
    _ => country.trim().isEmpty ? '国家.签证'.tr() : country.trim().toUpperCase(),
  };
}

/// 将签证类型代码转为详情页展示文案。
String _formatVisaTypeLabel(String visaType) {
  return switch (visaType.trim().toLowerCase()) {
    'work' => '服务详情.工作签'.tr(),
    'travel' => '服务详情.旅游签'.tr(),
    'tech' => '服务详情.技术签'.tr(),
    'nursing' => '服务详情.护理签'.tr(),
    'study' => '服务详情.留学签'.tr(),
    _ => visaType.trim().isEmpty ? '服务详情.签证服务'.tr() : visaType.trim(),
  };
}
