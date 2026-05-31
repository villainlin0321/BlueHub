import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../../shared/widgets/app_user_avatar.dart';
import '../../../utils/upload_picker_utils.dart';
import '../../auth/presentation/qualification_certification_flow.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../../visa/data/provider_models.dart';
import '../../visa/data/provider_providers.dart';
import '../data/dictionary_providers.dart';
import 'country_options_bottom_sheet.dart';
import 'widgets/company_my_info_widgets.dart';

final _serviceProviderMyInfoProfileProvider =
    FutureProvider.autoDispose<VisaProviderProfileVO>((ref) async {
      final service = ref.watch(providerServiceProvider);
      return service.getMyProfile();
    });

/// 服务商“我的信息”页，使用当前登录服务商资料接口渲染。
class ServiceProviderMyInfoPage extends ConsumerStatefulWidget {
  const ServiceProviderMyInfoPage({super.key});

  static const String _logoFallbackAsset = 'assets/images/mou588hj-vpl779h.png';
  static const String _idCardEmblemPlaceholderAsset =
      'assets/images/qualification_id_emblem.png';
  static const String _idCardPortraitPlaceholderAsset =
      'assets/images/qualification_id_portrait.png';
  static const String _licensePlaceholderAsset =
      'assets/images/qualification_license_placeholder.png';
  @override
  ConsumerState<ServiceProviderMyInfoPage> createState() =>
      _ServiceProviderMyInfoPageState();
}

class _ServiceProviderMyInfoPageState
    extends ConsumerState<ServiceProviderMyInfoPage> {
  bool _isSubmitting = false;
  String? _localAvatarPreviewPath;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final AsyncValue<VisaProviderProfileVO> profileAsync = ref.watch(
      _serviceProviderMyInfoProfileProvider,
    );
    final Map<String, String> countryLabelMap = ref
        .watch(countrySearchProvider(const CountrySearchQuery()))
        .maybeWhen(
          data: (result) => buildCountryLabelMap(result.list),
          orElse: () => const <String, String>{},
        );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                _Header(onBackTap: context.pop),
                Expanded(
                  child: profileAsync.when(
                    data: (VisaProviderProfileVO profile) =>
                        _ServiceProviderMyInfoContent(
                          profile: profile,
                          countryLabelMap: countryLabelMap,
                          localAvatarPreviewPath: _localAvatarPreviewPath,
                          onAvatarTap: () => _handleAvatarTap(profile),
                        ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => _ServiceProviderMyInfoErrorView(
                      onRetry: () =>
                          ref.invalidate(_serviceProviderMyInfoProfileProvider),
                    ),
                  ),
                ),
                _BottomActionBar(
                  bottomInset: bottomInset,
                  onTap: () => context.push(
                    RoutePaths.qualificationCertification,
                    extra: QualificationCertificationPageArgs(
                      role: QualificationCertificationRole.serviceProvider,
                    ),
                  ),
                ),
              ],
            ),
            if (_isSubmitting)
              Positioned.fill(
                child: ColoredBox(
                  color: const Color(0x33000000),
                  child: Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAvatarTap(VisaProviderProfileVO profile) async {
    if (_isSubmitting) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (BuildContext sheetContext) {
        return CompanyImageSourceBottomSheet(
          onClose: () => Navigator.of(sheetContext).pop(),
          onCameraTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickAndUploadAvatar(
              profile: profile,
              picker: UploadPickerUtils.pickFromCamera,
              errorMessage: '我的.打开相机失败'.tr(),
            );
          },
          onGalleryTap: () async {
            Navigator.of(sheetContext).pop();
            await _pickAndUploadAvatar(
              profile: profile,
              picker: UploadPickerUtils.pickFromGallery,
              errorMessage: '我的.打开相册失败'.tr(),
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar({
    required VisaProviderProfileVO profile,
    required Future<List<PickedUploadFile>> Function() picker,
    required String errorMessage,
  }) async {
    try {
      final List<PickedUploadFile> files = await picker();
      if (!mounted || files.isEmpty) {
        return;
      }

      PickedUploadFile selectedFile = files.first;
      for (final PickedUploadFile item in files) {
        if (item.isImage) {
          selectedFile = item;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _localAvatarPreviewPath = selectedFile.path;
        });
      }

      await _executeProfileAction(
        action: () async {
          final int logoId = await _uploadAvatar(selectedFile.path);
          await ref
              .read(providerServiceProvider)
              .updateMyProfile(
                request: UpdateVisaProviderBO(
                  companyName: profile.companyName,
                  unifiedCreditCode: profile.unifiedCreditCode,
                  legalPerson: profile.legalPerson,
                  contactPerson: profile.contactPerson,
                  contactPhone: profile.contactPhone,
                  contactEmail: profile.contactEmail,
                  website: profile.website,
                  yearsOfService: profile.yearsOfService,
                  logoId: logoId,
                  brief: profile.brief,
                  servicePromise: profile.servicePromise,
                  serviceCountries: profile.serviceCountries,
                ),
              );
        },
        successMessage: '我的.头像已更新'.tr(),
      );
      if (mounted) {
        setState(() {
          _localAvatarPreviewPath = null;
        });
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _localAvatarPreviewPath = null;
      });
      _showMessage(errorMessage);
    }
  }

  Future<void> _executeProfileAction({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });
    try {
      await action();
      ref.invalidate(_serviceProviderMyInfoProfileProvider);
      if (!mounted) {
        return;
      }
      _showMessage(successMessage);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_resolveErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<int> _uploadAvatar(String path) async {
    final FilePresignVO presign = await ref
        .read(fileServiceProvider)
        .uploadFile(
          path: path,
          scene: FileScene.avatar,
          errorMessage: '我的.头像上传失败'.tr(),
        );
    return presign.fileId;
  }

  String _resolveErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return '我的.保存失败'.tr();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ServiceProviderMyInfoContent extends StatelessWidget {
  const _ServiceProviderMyInfoContent({
    required this.profile,
    required this.countryLabelMap,
    required this.localAvatarPreviewPath,
    required this.onAvatarTap,
  });

  final VisaProviderProfileVO profile;
  final Map<String, String> countryLabelMap;
  final String? localAvatarPreviewPath;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final List<_InfoItem> infoItems = <_InfoItem>[
      _InfoItem(label: '我的.企业名称'.tr(), value: _textOrPlaceholder(profile.companyName)),
      _InfoItem(
        label: '我的.统一社会信用代码'.tr(),
        value: _textOrPlaceholder(profile.unifiedCreditCode),
      ),
      _InfoItem(label: '我的.法人姓名'.tr(), value: _textOrPlaceholder(profile.legalPerson)),
      _InfoItem(
        label: '我的.官方联系人'.tr(),
        value: _textOrPlaceholder(profile.contactPerson),
      ),
      _InfoItem(label: '我的.联系电话'.tr(), value: _textOrPlaceholder(profile.contactPhone)),
      _InfoItem(label: '我的.邮箱'.tr(), value: _textOrPlaceholder(profile.contactEmail)),
      _InfoItem(label: '我的.官网'.tr(), value: _textOrPlaceholder(profile.website)),
      _InfoItem(
        label: '我的.从业年限'.tr(),
        value: profile.yearsOfService > 0 ? '${profile.yearsOfService}' : '我的.未完善'.tr(),
      ),
      _InfoItem(
        label: '我的.国家地区'.tr(),
        value: _serviceCountriesText(profile.serviceCountries, countryLabelMap),
      ),
    ];
    final _ProviderQualificationDocs docs = _ProviderQualificationDocs.fromList(
      profile.qualificationDocs,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _InfoSection(
            avatarUrl: profile.logoUrl,
            localAvatarPreviewPath: localAvatarPreviewPath,
            onAvatarTap: onAvatarTap,
            items: infoItems,
          ),
          const SizedBox(height: 12),
          _QualificationSection(docs: docs),
          const SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '我的.注意重新提交审核'.tr(),
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 12,
                height: 18 / 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _textOrPlaceholder(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? '我的.未完善'.tr() : trimmed;
  }

  static String _serviceCountriesText(
    List<String> countries,
    Map<String, String> countryLabelMap,
  ) {
    final List<String> labels = countries
        .map((value) => resolveCountryLabel(value, countryLabelMap).trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (labels.isEmpty) {
      return '我的.未完善'.tr();
    }
    return labels.join('/');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBackTap});

  final VoidCallback onBackTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            left: 4,
            child: IconButton(
              onPressed: onBackTap,
              icon: const Icon(Icons.chevron_left, color: Color(0xFF262626)),
            ),
          ),
          Text(
            '我的.我的信息'.tr(),
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 17,
              fontWeight: FontWeight.w500,
              height: 24 / 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.avatarUrl,
    required this.localAvatarPreviewPath,
    required this.onAvatarTap,
    required this.items,
  });

  final String avatarUrl;
  final String? localAvatarPreviewPath;
  final VoidCallback onAvatarTap;
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              '我的.基础信息'.tr(),
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 22 / 16,
              ),
            ),
          ),
          _AvatarRow(
            avatarUrl: avatarUrl,
            localAvatarPath: localAvatarPreviewPath,
            onTap: onAvatarTap,
          ),
          for (int index = 0; index < items.length; index++) ...<Widget>[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
            ),
            _InfoRow(item: items[index]),
          ],
        ],
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  const _AvatarRow({
    required this.avatarUrl,
    required this.localAvatarPath,
    required this.onTap,
  });

  final String avatarUrl;
  final String? localAvatarPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Image.asset(
      ServiceProviderMyInfoPage._logoFallbackAsset,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
    );

    final String resolvedLocalAvatarPath = localAvatarPath?.trim() ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '我的.头像'.tr(),
                style: const TextStyle(
                  color: Color(0xFF262626),
                  fontSize: 16,
                  height: 22 / 16,
                ),
              ),
            ),
            if (resolvedLocalAvatarPath.isNotEmpty)
              ClipOval(
                child: Image.file(
                  File(resolvedLocalAvatarPath),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return AppUserAvatar(
                      imageUrl: avatarUrl,
                      size: 40,
                      placeholder: fallback,
                    );
                  },
                ),
              )
            else
              ClipOval(
                child: AppUserAvatar(
                  imageUrl: avatarUrl,
                  size: 40,
                  placeholder: fallback,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.item});

  final _InfoItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 15, 12, 15),
      child: Row(
        crossAxisAlignment: item.label.contains('\n')
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(
              item.label,
              style: const TextStyle(
                color: Color(0xFF262626),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 16,
                height: 22 / 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualificationSection extends StatelessWidget {
  const _QualificationSection({required this.docs});

  final _ProviderQualificationDocs docs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '我的.材料资质'.tr(),
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '我的.身份证'.tr(),
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _MaterialPreviewCard(
                  imageUrl: docs.idCardEmblem?.fileUrl ?? '',
                  placeholderAsset:
                      ServiceProviderMyInfoPage._idCardEmblemPlaceholderAsset,
                  height: 100,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MaterialPreviewCard(
                  imageUrl: docs.idCardPortrait?.fileUrl ?? '',
                  placeholderAsset:
                      ServiceProviderMyInfoPage._idCardPortraitPlaceholderAsset,
                  height: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _DocumentBlock(
                  label: '我的.营业执照'.tr(),
                  child: _MaterialPreviewCard(
                    imageUrl: docs.businessLicense?.fileUrl ?? '',
                    placeholderAsset:
                        ServiceProviderMyInfoPage._licensePlaceholderAsset,
                    height: 110,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _DocumentBlock(
                  label: '我的.特许经验许可'.tr(),
                  child: _MaterialPreviewCard(
                    imageUrl: docs.specialPermit?.fileUrl ?? '',
                    placeholderAsset:
                        ServiceProviderMyInfoPage._licensePlaceholderAsset,
                    height: 110,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentBlock extends StatelessWidget {
  const _DocumentBlock({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF262626),
              fontSize: 14,
              height: 20 / 14,
            ),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _MaterialPreviewCard extends StatelessWidget {
  const _MaterialPreviewCard({
    required this.imageUrl,
    required this.placeholderAsset,
    required this.height,
  });

  final String imageUrl;
  final String placeholderAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Image.asset(
      placeholderAsset,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFD9D9D9),
          width: 1,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      padding: const EdgeInsets.all(6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl.trim().isEmpty
            ? fallback
            : CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}

class _ServiceProviderMyInfoErrorView extends StatelessWidget {
  const _ServiceProviderMyInfoErrorView({required this.onRetry});

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
              '我的.加载服务商资料失败'.tr(),
              style: const TextStyle(
                color: Color(0xFF8C8C8C),
                fontSize: 14,
                height: 20 / 14,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('通用.重试'.tr())),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.bottomInset, required this.onTap});

  final double bottomInset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F000000),
            offset: Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 20),
      child: SizedBox(
        height: 44,
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF1677FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 22 / 16,
            ),
          ),
          child: Text('我的.修改信息'.tr()),
        ),
      ),
    );
  }
}

class _InfoItem {
  const _InfoItem({required this.label, required this.value});

  final String label;
  final String value;
}

class _ProviderQualificationDocs {
  const _ProviderQualificationDocs({
    this.businessLicense,
    this.specialPermit,
    this.idCardEmblem,
    this.idCardPortrait,
  });

  factory _ProviderQualificationDocs.fromList(List<QualificationDocVO> docs) {
    QualificationDocVO? businessLicense;
    QualificationDocVO? specialPermit;
    QualificationDocVO? idCardEmblem;
    QualificationDocVO? idCardPortrait;
    final List<QualificationDocVO> idCards = <QualificationDocVO>[];

    for (final QualificationDocVO doc in docs) {
      final String docType = doc.docType.trim();
      if (docType == 'business_license') {
        businessLicense ??= doc;
        continue;
      }
      if (docType == 'special_permit') {
        specialPermit ??= doc;
        continue;
      }
      if (docType == 'id_card') {
        idCards.add(doc);
      }
    }

    for (final QualificationDocVO doc in idCards) {
      final String name = doc.docName.trim();
      if (idCardEmblem == null && name.contains('国徽')) {
        idCardEmblem = doc;
        continue;
      }
      if (idCardPortrait == null && name.contains('人像')) {
        idCardPortrait = doc;
      }
    }

    if (idCards.isNotEmpty) {
      idCardEmblem ??= idCards.first;
      if (idCards.length > 1) {
        idCardPortrait ??= idCards[1];
      }
    }

    return _ProviderQualificationDocs(
      businessLicense: businessLicense,
      specialPermit: specialPermit,
      idCardEmblem: idCardEmblem,
      idCardPortrait: idCardPortrait,
    );
  }

  final QualificationDocVO? businessLicense;
  final QualificationDocVO? specialPermit;
  final QualificationDocVO? idCardEmblem;
  final QualificationDocVO? idCardPortrait;
}
