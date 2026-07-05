import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../shared/widgets/app_toast.dart';

import '../../../app/router/route_paths.dart';
import '../../../shared/network/api_exception.dart';
import '../../auth/presentation/qualification_certification_flow.dart';
import '../../employer/data/employer_models.dart';
import '../../employer/data/employer_providers.dart';
import '../../files/data/file_models.dart';
import '../../files/data/file_providers.dart';
import '../../../utils/upload_picker_utils.dart';
import '../data/dictionary_providers.dart';
import 'company_my_info_styles.dart';
import 'country_options_bottom_sheet.dart';
import 'widgets/company_my_info_widgets.dart';

import 'package:europepass/shared/ui/test_style.dart';
final _companyMyInfoProfileProvider =
    FutureProvider.autoDispose<EmployerProfileVO>((ref) async {
      final service = ref.watch(employerServiceProvider);
      return service.getEmployerProfile();
    });

class CompanyMyInfoPageArgs {
  const CompanyMyInfoPageArgs({
    this.profileId,
    required this.titleKey,
    required this.showBottomAction,
  });

  const CompanyMyInfoPageArgs.my()
    : profileId = null,
      titleKey = '我的.我的信息',
      showBottomAction = true;

  const CompanyMyInfoPageArgs.readonly({required this.profileId})
    : titleKey = '我的.企业信息',
      showBottomAction = false;

  final int? profileId;
  final String titleKey;
  final bool showBottomAction;

  bool get isReadonly => profileId != null;
}

/// 企业端“我的信息”页，按 Figma 设计展示企业基础资料与材料资质。
class CompanyMyInfoPage extends ConsumerStatefulWidget {
  const CompanyMyInfoPage({
    super.key,
    this.args = const CompanyMyInfoPageArgs.my(),
  });

  final CompanyMyInfoPageArgs args;

  static const String _avatarFallbackAsset =
      'assets/images/mou64ult-sj15mxj.png';
  static const String _qualificationPlaceholderAsset =
      'assets/images/qualification_license_placeholder.png';

  @override
  ConsumerState<CompanyMyInfoPage> createState() => _CompanyMyInfoPageState();
}

class _CompanyMyInfoPageState extends ConsumerState<CompanyMyInfoPage> {
  bool _isSubmitting = false;
  String? _localAvatarPreviewPath;

  @override
  Widget build(BuildContext context) {
    final CompanyMyInfoPageArgs args = widget.args;
    final AsyncValue<EmployerProfileVO>? profileAsync = args.isReadonly
        ? null
        : ref.watch(_companyMyInfoProfileProvider);
    final AsyncValue<EmployerPublicVO>? publicProfileAsync = args.isReadonly
        ? ref.watch(employerPublicProfileProvider(args.profileId!))
        : null;
    final Map<String, String> countryLabelMap = ref
        .watch(countrySearchProvider(const CountrySearchQuery()))
        .maybeWhen(
          data: (result) => buildCountryLabelMap(result.list),
          orElse: () => const <String, String>{},
        );

    return Scaffold(
      backgroundColor: CompanyMyInfoStyles.pageBackground,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                CompanyMyInfoHeader(
                  onBackTap: context.pop,
                  title: args.titleKey.tr(),
                ),
                Expanded(
                  child: args.isReadonly
                      ? publicProfileAsync!.when(
                          data: (EmployerPublicVO profile) =>
                              _CompanyPublicInfoContent(
                                profile: profile,
                                countryLabelMap: countryLabelMap,
                              ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => _CompanyMyInfoErrorView(
                            message: '我的.加载企业信息失败'.tr(),
                            onRetry: () => ref.invalidate(
                              employerPublicProfileProvider(args.profileId!),
                            ),
                          ),
                        )
                      : profileAsync!.when(
                          data: (EmployerProfileVO profile) =>
                              _CompanyMyInfoContent(
                                profile: profile,
                                countryLabelMap: countryLabelMap,
                                localAvatarPreviewPath: _localAvatarPreviewPath,
                                onAvatarTap: () => _handleAvatarTap(profile),
                                showBottomAction: args.showBottomAction,
                              ),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (_, __) => _CompanyMyInfoErrorView(
                            message: '我的.加载企业资料失败'.tr(),
                            onRetry: () =>
                                ref.invalidate(_companyMyInfoProfileProvider),
                          ),
                        ),
                ),
              ],
            ),
            if (_isSubmitting && args.showBottomAction)
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

  Future<void> _handleAvatarTap(EmployerProfileVO profile) async {
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
    required EmployerProfileVO profile,
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
              .read(employerServiceProvider)
              .updateEmployerProfile(
                request: UpdateEmployerBO(
                  companyName: profile.companyName,
                  industry: profile.industry,
                  companySize: profile.companySize,
                  logoId: logoId,
                  description: profile.description,
                  website: profile.website,
                  foundedYear: profile.foundedYear,
                  country: profile.country,
                  city: profile.city,
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
      ref.invalidate(_companyMyInfoProfileProvider);
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
    AppToast.show(message);
  }
}

class _CompanyMyInfoContent extends StatelessWidget {
  const _CompanyMyInfoContent({
    required this.profile,
    required this.countryLabelMap,
    required this.localAvatarPreviewPath,
    required this.onAvatarTap,
    required this.showBottomAction,
  });

  final EmployerProfileVO profile;
  final Map<String, String> countryLabelMap;
  final String? localAvatarPreviewPath;
  final VoidCallback onAvatarTap;
  final bool showBottomAction;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;
    final List<_CompanyInfoField> basicInfoFields = <_CompanyInfoField>[
      _CompanyInfoField(label: '我的.企业名称'.tr(), value: _companyName),
      _CompanyInfoField(label: '我的.注册国家'.tr(), value: _registeredCountry),
      _CompanyInfoField(label: '我的.所在城市'.tr(), value: _city),
      _CompanyInfoField(label: '我的.所属行业'.tr(), value: _industry),
      _CompanyInfoField(label: '我的.公司规模'.tr(), value: _companySize),
      _CompanyInfoField(label: '我的.成立年份'.tr(), value: _foundedYear),
      _CompanyInfoField(label: '我的.官网地址'.tr(), value: _website),
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        CompanyMyInfoStyles.pageHorizontalPadding,
        12,
        CompanyMyInfoStyles.pageHorizontalPadding,
        bottomInset + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CompanyMyInfoSectionCard(
            title: '我的.基础信息'.tr(),
            child: Column(
              children: <Widget>[
                CompanyMyInfoAvatarRow(
                  label: '我的.头像'.tr(),
                  avatarUrl: profile.logoUrl,
                  localAvatarPath: localAvatarPreviewPath,
                  fallbackAssetPath: CompanyMyInfoPage._avatarFallbackAsset,
                  onTap: onAvatarTap,
                ),
                for (int index = 0; index < basicInfoFields.length; index++)
                  CompanyMyInfoValueRow(
                    label: basicInfoFields[index].label,
                    value: basicInfoFields[index].value,
                    showDivider: index != basicInfoFields.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompanyMyInfoSectionCard(
            title: '我的.材料资质'.tr(),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                CompanyQualificationPreview(
                  title: '我的.营业执照'.tr(),
                  imageUrl: _businessLicenseDoc?.fileUrl,
                  fallbackAssetPath:
                      CompanyMyInfoPage._qualificationPlaceholderAsset,
                ),
                CompanyQualificationPreview(
                  title: '我的.特许经验许可'.tr(),
                  imageUrl: _specialPermitDoc?.fileUrl,
                  fallbackAssetPath:
                      CompanyMyInfoPage._qualificationPlaceholderAsset,
                ),
              ],
            ),
          ),
          if (showBottomAction) ...<Widget>[
            const SizedBox(height: 12),
            Text('我的.注意重新提交审核'.tr(), style: CompanyMyInfoStyles.noteText),
            const SizedBox(height: 24),
            CompanyMyInfoPrimaryButton(
              label: '我的.修改信息'.tr(),
              onTap: () {
                final QualificationCertificationDraft draft =
                    QualificationCertificationDraft()
                      ..fillFromEmployerProfile(
                        profile,
                        countryLabelMap: countryLabelMap,
                      );
                context.push(
                  RoutePaths.qualificationCertification,
                  extra: QualificationCertificationPageArgs(
                    role: QualificationCertificationRole.company,
                    draft: draft,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String get _companyName {
    return _displayText(profile.companyName, placeholder: '我的.企业名称待完善'.tr());
  }

  String get _registeredCountry {
    final String value = profile.country.trim();
    if (value.isEmpty) {
      return '我的.未完善'.tr();
    }
    return resolveCountryLabel(value, countryLabelMap);
  }

  String get _city => _displayText(profile.city);

  String get _industry => _displayText(profile.industry);

  String get _companySize => _displayText(profile.companySize);

  String get _foundedYear {
    if (profile.foundedYear <= 0) {
      return '我的.未完善'.tr();
    }
    return '${profile.foundedYear}${'我的.年份后缀'.tr()}';
  }

  String get _website => _displayText(profile.website);

  QualificationDocVO? get _businessLicenseDoc =>
      _qualificationDocByType(QualificationDocType.businessLicense.apiValue);

  QualificationDocVO? get _specialPermitDoc =>
      _qualificationDocByType(QualificationDocType.specialPermit.apiValue);

  /// 从同类型资质中优先挑选“最新且有可用图片地址”的那条记录，兼容历史重复上传场景。
  QualificationDocVO? _qualificationDocByType(String docType) {
    QualificationDocVO? fallbackMatch;
    QualificationDocVO? preferredMatch;
    DateTime? preferredCreatedAt;

    for (final QualificationDocVO doc in profile.qualificationDocs) {
      if (doc.docType.trim() != docType) {
        continue;
      }
      fallbackMatch = doc;

      // 优先使用带有效 URL 的记录，避免命中旧的空壳文档导致页面不回显。
      if (doc.fileUrl.trim().isEmpty) {
        continue;
      }

      final DateTime? createdAt = DateTime.tryParse(doc.createdAt.trim());
      if (preferredMatch == null) {
        preferredMatch = doc;
        preferredCreatedAt = createdAt;
        continue;
      }

      if (_isQualificationDocNewer(createdAt, preferredCreatedAt)) {
        preferredMatch = doc;
        preferredCreatedAt = createdAt;
      }
    }
    return preferredMatch ?? fallbackMatch;
  }

  /// 比较两条资质记录的时间，新记录优先；若时间不可解析，则按遍历顺序让后出现的记录覆盖。
  bool _isQualificationDocNewer(DateTime? candidate, DateTime? current) {
    if (candidate == null) {
      return current == null;
    }
    if (current == null) {
      return true;
    }
    return !candidate.isBefore(current);
  }

  /// 返回字段展示文本，空值时统一回退到国际化占位文案。
  String _displayText(String value, {String? placeholder}) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? (placeholder ?? '我的.未完善'.tr()) : trimmed;
  }
}

class _CompanyInfoField {
  const _CompanyInfoField({required this.label, required this.value});

  final String label;
  final String value;
}

class _CompanyMyInfoErrorView extends StatelessWidget {
  const _CompanyMyInfoErrorView({required this.message, required this.onRetry});

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
              style: TestStyle.pingFangRegular(fontSize: 14, color: CompanyMyInfoStyles.secondaryText),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text('我的.重试'.tr())),
          ],
        ),
      ),
    );
  }
}

class _CompanyPublicInfoContent extends StatelessWidget {
  const _CompanyPublicInfoContent({
    required this.profile,
    required this.countryLabelMap,
  });

  final EmployerPublicVO profile;
  final Map<String, String> countryLabelMap;

  @override
  Widget build(BuildContext context) {
    final List<_CompanyInfoField> basicInfoFields = <_CompanyInfoField>[
      _CompanyInfoField(
        label: '我的.企业名称'.tr(),
        value: _displayText(profile.companyName),
      ),
      _CompanyInfoField(
        label: '服务详情.认证状态'.tr(),
        value: profile.isVerified ? '服务详情.已认证'.tr() : '服务详情.未认证'.tr(),
      ),
      _CompanyInfoField(
        label: '我的.注册国家'.tr(),
        value: _resolveCountry(profile.country),
      ),
      _CompanyInfoField(
        label: '我的.所在城市'.tr(),
        value: _displayText(profile.city),
      ),
      _CompanyInfoField(
        label: '我的.所属行业'.tr(),
        value: _displayText(profile.industry),
      ),
      _CompanyInfoField(
        label: '我的.公司规模'.tr(),
        value: _displayText(profile.companySize),
      ),
      _CompanyInfoField(label: '我的.成立年份'.tr(), value: _foundedYearText),
      _CompanyInfoField(
        label: '我的.官网地址'.tr(),
        value: _displayText(profile.website),
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        CompanyMyInfoStyles.pageHorizontalPadding,
        12,
        CompanyMyInfoStyles.pageHorizontalPadding,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CompanyMyInfoSectionCard(
            title: '我的.基础信息'.tr(),
            child: Column(
              children: <Widget>[
                CompanyMyInfoAvatarRow(
                  label: '我的.头像'.tr(),
                  avatarUrl: profile.logoUrl,
                  fallbackAssetPath: CompanyMyInfoPage._avatarFallbackAsset,
                ),
                for (int index = 0; index < basicInfoFields.length; index++)
                  CompanyMyInfoValueRow(
                    label: basicInfoFields[index].label,
                    value: basicInfoFields[index].value,
                    showDivider: index != basicInfoFields.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          CompanyMyInfoSectionCard(
            title: '服务详情.简介'.tr(),
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
            child: Text(
              profile.description.trim().isEmpty
                  ? '服务详情.暂无商家简介'.tr()
                  : profile.description,
              style: CompanyMyInfoStyles.fieldValue.copyWith(
                color: const Color(0xFF595959),
                height: 22 / 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveCountry(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '我的.未完善'.tr();
    }
    return resolveCountryLabel(trimmed, countryLabelMap);
  }

  String get _foundedYearText {
    if (profile.foundedYear <= 0) {
      return '我的.未完善'.tr();
    }
    return '${profile.foundedYear}${'我的.年份后缀'.tr()}';
  }

  String _displayText(String value) {
    final String trimmed = value.trim();
    return trimmed.isEmpty ? '我的.未完善'.tr() : trimmed;
  }
}
