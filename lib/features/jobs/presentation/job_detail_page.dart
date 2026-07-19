import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../home/data/home_providers.dart';
import '../../me/data/dictionary_providers.dart';
import '../../../shared/network/api_error_feedback.dart';
import '../../../shared/network/models/dictionary_models.dart';
import '../../../shared/network/page_result.dart';
import '../../../shared/widgets/app_svg_icon.dart';
import '../../auth/application/auth_role_mapper.dart';
import '../data/job_models.dart';
import '../data/job_providers.dart';
import '../../me/data/collection_models.dart' show CollectionBO;
import '../../me/data/collection_providers.dart';
import '../../message/application/chat/chat_page_args.dart';
import '../../messages/data/message_models.dart';
import '../../messages/data/message_providers.dart';
import '../../me/presentation/company_my_info_page.dart';
import 'job_apply_helper.dart';

import 'package:europepass/shared/ui/test_style.dart';

/// 职位详情页参数：当前至少透传岗位 ID，供“投递简历”调用真实接口。
class JobDetailPageArgs {
  const JobDetailPageArgs({required this.jobId});

  final int? jobId;
}

class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage({super.key, this.args});

  final JobDetailPageArgs? args;

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  bool _isApplying = false;
  bool _isApplied = false;
  bool _isCollecting = false;
  bool _isContacting = false;
  bool _isLoading = true;
  String? _errorMessage;
  bool? _isCollectedOverride;
  JobDetailVO? _detail;

  static const String _companyAvatarAsset =
      'assets/images/job_detail_company_avatar.png';
  static const String _mapAsset = 'assets/images/job_detail_map-56586a.png';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobDetail();
    });
  }

  void _showMessage(BuildContext context, String message) {
    AppToast.show(message);
  }

  void _handleBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RoutePaths.jobs);
  }

  /// 拉取岗位详情，并在页面内维护加载态、错误态和真实详情数据。
  Future<void> _loadJobDetail() async {
    final int? jobId = widget.args?.jobId;
    if (jobId == null || jobId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = '招聘.岗位信息缺失'.tr();
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await ref
          .read(jobServiceProvider)
          .getJobDetail(jobId: jobId);
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _detail = detail;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _resolveDetailErrorMessage(error);
      });
    }
  }

  /// 统一提取详情请求失败文案，优先显示接口返回的真实错误信息。
  String _resolveDetailErrorMessage(Object error) {
    return ApiErrorFeedback.resolveMessage(error, fallback: '招聘.岗位详情加载失败'.tr());
  }

  /// 当前收藏状态，优先采用本地交互后的覆盖值。
  bool get _isCollected =>
      _isCollectedOverride ?? (_detail?.isCollected ?? false);

  /// 切换岗位收藏状态，并同步调用收藏接口。
  Future<void> _toggleCollection() async {
    final JobDetailVO? detail = _detail;
    if (_isCollecting || detail == null) {
      return;
    }

    setState(() {
      _isCollecting = true;
    });

    final bool wasCollected = _isCollected;

    try {
      final service = ref.read(collectionServiceProvider);
      final request = CollectionBO(targetType: 'job', targetId: detail.jobId);
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
      _showMessage(context, wasCollected ? '招聘.已取消收藏'.tr() : '招聘.收藏成功'.tr());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isCollecting = false;
      });
      _showMessage(context, _resolveDetailErrorMessage(error));
    }
  }

  /// 创建或获取与雇主的会话，成功后直接进入聊天页。
  Future<void> _handleChat() async {
    final JobDetailVO? detail = _detail;
    if (_isContacting || detail == null) {
      return;
    }
    if (detail.employer.employerId <= 0) {
      _showMessage(context, '招聘.雇主信息缺失'.tr());
      return;
    }

    setState(() {
      _isContacting = true;
    });

    try {
      final Map<String, dynamic> response = await ref
          .read(messageServiceProvider)
          .createConversation(
            request: CreateConversationBO(
              targetUserId: detail.employer.employerId,
              targetUserRole: employerRoleId,
            ),
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _isContacting = false;
      });
      final int conversationId = _readConversationId(response);
      context.push(
        RoutePaths.chat,
        extra: ChatPageArgs(
          targetUserId: detail.employer.employerId,
          targetUserRole: employerRoleId,
          nickname: detail.employer.name.trim().isEmpty
              ? '招聘.企业'.tr()
              : detail.employer.name,
          avatarUrl: detail.employer.logoUrl,
          conversationId: conversationId,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isContacting = false;
      });
      _showMessage(context, _resolveDetailErrorMessage(error));
    }
  }

  int _readConversationId(Map<String, dynamic> raw) {
    final Object? direct = raw['conversationId'] ?? raw['conversation_id'];
    if (direct is int) {
      return direct;
    }
    if (direct is num) {
      return direct.toInt();
    }
    if (direct is String) {
      return int.tryParse(direct) ?? 0;
    }

    final Object? nestedConversation = raw['conversation'];
    if (nestedConversation is Map<String, dynamic>) {
      final Object? nestedId =
          nestedConversation['conversationId'] ??
          nestedConversation['conversation_id'];
      if (nestedId is int) {
        return nestedId;
      }
      if (nestedId is num) {
        return nestedId.toInt();
      }
      if (nestedId is String) {
        return int.tryParse(nestedId) ?? 0;
      }
    }
    return 0;
  }

  /// 处理详情页投递操作，并根据接口结果切换按钮状态。
  Future<void> _handleApply() async {
    if (_isApplying || _isApplied) {
      return;
    }

    setState(() {
      _isApplying = true;
    });

    final JobApplySubmissionResult result = await submitJobApplication(
      context,
      jobId: widget.args?.jobId,
    );
    if (!mounted) {
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _isApplying = false;
        _isApplied = true;
      });
      _showMessage(context, '招聘.投递成功'.tr());
      return;
    }

    setState(() {
      _isApplying = false;
    });
    if (result.shouldShowError) {
      _showMessage(context, result.errorMessage!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => _handleBack(context),
          icon: const AppSvgIcon(
            assetPath: 'assets/images/service_detail_back.svg',
            fallback: Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF262626),
          ),
        ),
        title: Text(
          '招聘.招聘详情'.tr(),
          style: TestStyle.pingFangSemibold(
            fontSize: 17,
            color: const Color(0xE6000000),
          ),
        ),
        actions: <Widget>[
          Opacity(
            opacity: _isCollecting || _detail == null ? 0.4 : 1,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _isCollecting || _detail == null
                  ? null
                  : _toggleCollection,
              child: SizedBox(
                width: 20,
                height: 20,
                child: AppSvgIcon(
                  assetPath: _isCollected
                      ? 'assets/images/service_detail_favorite_fill.svg'
                      : 'assets/images/service_detail_favorite.svg',
                  fallback: _isCollected
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 20,
                  color: _isCollected
                      ? const Color(0xFFFAAD14)
                      : const Color(0xFF262626),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showMessage(context, '招聘.分享开发中'.tr()),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: AppSvgIcon(
                assetPath: 'assets/images/service_detail_share.svg',
                fallback: Icons.share_outlined,
                size: 20,
                color: Color(0xFF262626),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _BottomActionBar(
        onChatTap: _handleChat,
        onApplyTap: _handleApply,
        isChatting: _isContacting,
        isApplying: _isApplying,
        isApplied: _isApplied,
      ),
    );
  }

  /// 根据详情请求状态切换加载、错误和真实内容页面。
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _JobDetailErrorState(
        message: _errorMessage!,
        onRetry: _loadJobDetail,
      );
    }

    final detail = _detail;
    if (detail == null) {
      return _JobDetailErrorState(
        message: '招聘.岗位详情为空'.tr(),
        onRetry: _loadJobDetail,
      );
    }

    final AsyncValue<PageResult<CountryVO>> countriesAsync = ref.watch(
      countrySearchProvider(const CountrySearchQuery(page: 1, pageSize: 300)),
    );
    final Map<String, String> countryLabelMap = _buildCountryLabelMap(
      countriesAsync.asData?.value.list ?? const <CountryVO>[],
    );
    final String resolvedCountryLabel = _resolveCountryLabel(
      detail.country,
      countryLabelMap,
    );
    final String locationText = detail.buildLocationText(
      countryLabel: resolvedCountryLabel,
    );
    final String addressText = detail.buildAddressText(
      countryLabel: resolvedCountryLabel,
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        _JobHeaderSection(detail: detail, locationText: locationText),
        const SizedBox(height: 1),
        _EmployerCard(
          employer: detail.employer,
          fallbackAssetPath: _companyAvatarAsset,
        ),
        const SizedBox(height: 1),
        _JobDescriptionSection(detail: detail),
        const SizedBox(height: 1),
        _LocationSection(
          detail: detail,
          mapAssetPath: _mapAsset,
          addressText: addressText,
        ),
      ],
    );
  }
}

class _JobHeaderSection extends StatelessWidget {
  const _JobHeaderSection({required this.detail, required this.locationText});

  final JobDetailVO detail;
  final String locationText;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Text(
                  detail.title,
                  style: TestStyle.semibold(
                    fontSize: 22,
                    color: const Color(0xFF262626),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                detail.salaryText,
                style: TestStyle.medium(
                  fontSize: 16,
                  color: const Color(0xFFFE5815),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: detail.requirements
                .map((String item) => item.trim())
                .where((String item) => item.isNotEmpty)
                .map((String tag) => _BorderTag(label: tag))
                .toList(),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              const Icon(
                Icons.location_on_rounded,
                size: 16,
                color: Color(0xFFBCBCBC),
              ),
              const SizedBox(width: 4),
              Text(
                locationText,
                style: TestStyle.regular(
                  fontSize: 12,
                  color: const Color(0xFF595959),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BorderTag extends StatelessWidget {
  const _BorderTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: const Color(0xFFA3AFD4)),
      ),
      child: Text(
        label,
        style: TestStyle.regular(fontSize: 10, color: const Color(0xFF546D96)),
      ),
    );
  }
}

class _EmployerCard extends StatelessWidget {
  const _EmployerCard({
    required this.employer,
    required this.fallbackAssetPath,
  });

  final EmployerInfoVO employer;
  final String fallbackAssetPath;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: _EmployerLogo(
              logoUrl: employer.logoUrl,
              fallbackAssetPath: fallbackAssetPath,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  employer.name,
                  style: TestStyle.medium(
                    fontSize: 16,
                    color: const Color(0xFF262626),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employer.subtitleText,
                  style: TestStyle.regular(
                    fontSize: 12,
                    color: const Color(0xFF8C8C8C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: Color(0xFFBFBFBF),
          ),
        ],
      ),
    );
    if (employer.employerId <= 0) {
      return content;
    }

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => context.push(
          RoutePaths.companyMyInfo,
          extra: CompanyMyInfoPageArgs.readonly(profileId: employer.employerId),
        ),
        child: content,
      ),
    );
  }
}

class _JobDescriptionSection extends StatelessWidget {
  const _JobDescriptionSection({required this.detail});

  final JobDetailVO detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '招聘.职位详情'.tr(),
            style: TestStyle.pingFangSemibold(
              fontSize: 18,
              color: const Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            detail.description.trim(),
            style: TestStyle.regular(
              fontSize: 14,
              color: const Color(0xFF595959),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.detail,
    required this.mapAssetPath,
    required this.addressText,
  });

  final JobDetailVO detail;
  final String mapAssetPath;
  final String addressText;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '招聘.工作地点'.tr(),
            style: TestStyle.pingFangMedium(
              fontSize: 16,
              color: const Color(0xFF262626),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            addressText,
            style: TestStyle.regular(
              fontSize: 14,
              color: const Color(0xFF8C8C8C),
            ),
          ),
          if (detail.coordinateText != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              detail.coordinateText!,
              style: TestStyle.regular(
                fontSize: 12,
                color: const Color(0xFFBFBFBF),
              ),
            ),
          ],
          const SizedBox(height: 12),
          // ClipRRect(
          //   borderRadius: BorderRadius.circular(12),
          //   child: Image.asset(
          //     mapAssetPath,
          //     width: double.infinity,
          //     height: 180,
          //     fit: BoxFit.cover,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class _EmployerLogo extends StatelessWidget {
  const _EmployerLogo({required this.logoUrl, required this.fallbackAssetPath});

  final String logoUrl;
  final String fallbackAssetPath;

  /// 优先展示接口返回的企业 Logo，失败时回退到本地占位图。
  @override
  Widget build(BuildContext context) {
    if (logoUrl.trim().isEmpty) {
      return Image.asset(
        fallbackAssetPath,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      );
    }
    if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: logoUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) {
          return Image.asset(
            fallbackAssetPath,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
          );
        },
      );
    }
    return Image.asset(
      fallbackAssetPath,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );
  }
}

class _JobDetailErrorState extends StatelessWidget {
  const _JobDetailErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  /// 详情加载失败时展示重试入口，避免空白页。
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFBFBFBF),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TestStyle.regular(fontSize: 14, color: Color(0xFF8C8C8C)),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                onRetry();
              },
              child: Text('通用.重试'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.onChatTap,
    required this.onApplyTap,
    required this.isChatting,
    required this.isApplying,
    required this.isApplied,
  });

  final VoidCallback onChatTap;
  final VoidCallback onApplyTap;
  final bool isChatting;
  final bool isApplying;
  final bool isApplied;

  @override
  Widget build(BuildContext context) {
    final secondaryStyle = TestStyle.regular(
      fontSize: 16,
      color: const Color(0xFF171A1D),
    );
    final primaryStyle = TestStyle.regular(fontSize: 16, color: Colors.white);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0), width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 169,
              child: OutlinedButton(
                onPressed: isChatting ? null : onChatTap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: Color(0xFFD9D9D9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.white,
                ),
                child: Text(
                  isChatting ? '招聘.创建会话中'.tr() : '招聘.立即沟通'.tr(),
                  style: secondaryStyle,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 170,
              child: FilledButton(
                onPressed: isApplying || isApplied ? null : onApplyTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: const Color(0xFF096DD9),
                  disabledBackgroundColor: const Color(0xFF91C3F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isApplied
                      ? '招聘.已投递'.tr()
                      : (isApplying ? '招聘.投递中'.tr() : '招聘.投递简历'.tr()),
                  style: primaryStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension on JobDetailVO {
  /// 组装详情页顶部薪资文案。
  String get salaryText {
    final String currency = salaryCurrency.isEmpty ? '¥' : salaryCurrency;
    final String minText = _formatNumber(salaryMin);
    final String maxText = salaryMax > 0 ? _formatNumber(salaryMax) : '';
    final String range = maxText.isEmpty
        ? '$currency$minText'
        : '$currency$minText~$maxText';
    return salaryPeriod.isEmpty ? range : '$range/$salaryPeriod';
  }

  /// 组装地点文案，支持替换国家展示名称。
  String buildLocationText({String? countryLabel}) {
    final List<String> parts = <String>[
      (countryLabel ?? country).trim(),
      city.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? '招聘.地点待更新'.tr() : parts.join('·');
  }

  /// 组装详细地址文案，地址为空时回退到地点文案。
  String buildAddressText({String? countryLabel}) {
    final String addressText = address.trim();
    return addressText.isEmpty
        ? buildLocationText(countryLabel: countryLabel)
        : addressText;
  }

  /// 组装经纬度展示文案。
  String? get coordinateText {
    if (latitude == 0 && longitude == 0) {
      return null;
    }
    return '招聘.坐标'.tr(
      namedArgs: <String, String>{
        'lat': latitude.toStringAsFixed(4),
        'lng': longitude.toStringAsFixed(4),
      },
    );
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

Map<String, String> _buildCountryLabelMap(List<CountryVO> countries) {
  return <String, String>{
    for (final CountryVO item in countries)
      if (item.countryCode.trim().isNotEmpty && item.nameZh.trim().isNotEmpty)
        item.countryCode.trim(): item.nameZh.trim(),
  };
}

String _resolveCountryLabel(String value, Map<String, String> countryLabelMap) {
  final String trimmed = value.trim();
  return countryLabelMap[trimmed] ?? trimmed;
}

extension on EmployerInfoVO {
  /// 组装企业副标题，优先展示行业与规模。
  String get subtitleText {
    final List<String> parts = <String>[
      industry.trim(),
      size.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);
    return parts.isEmpty ? '招聘.企业信息待更新'.tr() : parts.join('·');
  }
}
