import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/page_result.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../me/data/collection_providers.dart';
import '../../service_detail/presentation/service_detail_page.dart';
import '../application/search_page/visa_provider_search_controller.dart';
import '../application/search_page/visa_provider_search_state.dart';
import '../data/provider_models.dart';
import '../data/provider_providers.dart';
import 'widgets/visa_provider_search_page_view.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';
class VisaProviderSearchPage extends ConsumerStatefulWidget {
  const VisaProviderSearchPage({super.key});

  @override
  ConsumerState<VisaProviderSearchPage> createState() =>
      _VisaProviderSearchPageState();
}

class _VisaProviderSearchPageState
    extends ConsumerState<VisaProviderSearchPage> {
  static const String _backAsset = 'assets/images/service_detail_back.svg';
  static const String _searchAsset =
      'assets/images/company_application_search.svg';

  late final TextEditingController _searchController = TextEditingController()
    ..addListener(_handleInputChanged);
  late final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(visaProviderSearchControllerProvider.notifier).loadHistory();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    ref
        .read(visaProviderSearchControllerProvider.notifier)
        .handleInputChanged(_searchController.text);
  }

  Future<void> _handleSubmit([String? value]) async {
    FocusScope.of(context).unfocus();
    await ref
        .read(visaProviderSearchControllerProvider.notifier)
        .submitKeyword(value ?? _searchController.text);
  }

  Future<void> _handleHistoryTap(String keyword) async {
    _searchController.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    await _handleSubmit(keyword);
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.visa);
  }

  void _handleResultTap(VisaProviderListVO item, bool isCollected) {
    context.push(
      RoutePaths.serviceDetail,
      extra: ServiceDetailPageArgs(
        packageId: item.latestPackage.packageId,
        providerId: item.providerId,
        initialIsCollected: isCollected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<VisaProviderSearchState>(visaProviderSearchControllerProvider, (
      VisaProviderSearchState? previous,
      VisaProviderSearchState next,
    ) {
      if (previous?.feedbackId == next.feedbackId ||
          next.feedbackMessage == null) {
        return;
      }
      AppToast.show(next.feedbackMessage!);
      ref.read(visaProviderSearchControllerProvider.notifier).clearFeedback();
    });

    final VisaProviderSearchState state = ref.watch(
      visaProviderSearchControllerProvider,
    );
    final AsyncValue<PageResult<VisaProviderListVO>>? providersAsync =
        state.isShowingResults
        ? ref.watch(
            visaProviderListProvider(
              VisaProviderListQuery(
                page: 1,
                pageSize: 50,
                keyword: state.submittedKeyword,
              ),
            ),
          )
        : null;
    final AsyncValue<Set<int>>? collectedPackageIdsAsync =
        state.isShowingResults
        ? ref.watch(collectedVisaPackageIdsProvider)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        toolbarHeight: 48,
        titleSpacing: 0,
        leadingWidth: 44,
        leading: IconButton(
          onPressed: _handleBack,
          icon: const AppSvgIcon(
            assetPath: _backAsset,
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xE6000000),
          ),
        ),
        title: _SearchAppBarField(
          controller: _searchController,
          focusNode: _focusNode,
          searchAssetPath: _searchAsset,
          onSubmitted: _handleSubmit,
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _handleSubmit,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF096DD9),
                minimumSize: const Size(52, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                '通用.搜索'.tr(),
                style: TestStyle.pingFangRegular(fontSize: 15, color: Color(0xFF096DD9)),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: VisaProviderSearchPageView(
          state: state,
          providersAsync: providersAsync,
          collectedPackageIdsAsync: collectedPackageIdsAsync,
          onHistoryTap: _handleHistoryTap,
          onResultTap: _handleResultTap,
          onRetrySearch: _handleSubmit,
          onClearHistory: () {
            ref
                .read(visaProviderSearchControllerProvider.notifier)
                .clearHistory();
          },
        ),
      ),
    );
  }
}

class _SearchAppBarField extends StatelessWidget {
  const _SearchAppBarField({
    required this.controller,
    required this.focusNode,
    required this.searchAssetPath,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String searchAssetPath;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      margin: const EdgeInsets.only(left: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          AppSvgIcon(
            assetPath: searchAssetPath,
            fallback: Icons.search_rounded,
            size: 16,
            color: const Color(0xFFBFBFBF),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              cursorColor: const Color(0xFF096DD9),
              style: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFF262626)),
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: '首页.搜索签证服务欧洲岗位'.tr(),
                hintStyle: TestStyle.pingFangRegular(fontSize: 14, color: Color(0xFFBFBFBF)),
              ),
              onSubmitted: onSubmitted,
            ),
          ),
          const SizedBox(width: 9),
        ],
      ),
    );
  }
}
