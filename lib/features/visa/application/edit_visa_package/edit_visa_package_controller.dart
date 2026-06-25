import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/data/config_models.dart';
import '../../../config/data/config_providers.dart';
import '../../../../shared/network/services/config_service.dart';
import '../../../../shared/models/app_currency.dart';
import '../../data/visa_package_models.dart';
import '../../data/visa_package_providers.dart';
import 'edit_visa_package_state.dart';

final editVisaPackageControllerProvider =
    NotifierProvider.autoDispose<
      EditVisaPackageController,
      EditVisaPackageState
    >(EditVisaPackageController.new);

class EditVisaPackageMaterialDraftInput {
  const EditVisaPackageMaterialDraftInput({
    required this.name,
    required this.description,
    required this.isRequired,
    required this.exampleFileIds,
  });

  final String name;
  final String description;
  final bool isRequired;
  final List<int> exampleFileIds;
}

class EditVisaPackageTierDraftInput {
  const EditVisaPackageTierDraftInput({
    required this.tierId,
    required this.name,
    required this.price,
    required this.description,
    required this.showMaterials,
    required this.selectedServiceTagCodes,
    required this.customServices,
    required this.materials,
  });

  final int tierId;
  final String name;
  final String price;
  final String description;
  final bool showMaterials;
  final List<String> selectedServiceTagCodes;
  final List<String> customServices;
  final List<EditVisaPackageMaterialDraftInput> materials;
}

class EditVisaPackageFormDraft {
  const EditVisaPackageFormDraft({
    required this.name,
    required this.estimatedDays,
    required this.currency,
    required this.coverImageIds,
    required this.coverImages,
    required this.tiers,
  });

  final String name;
  final String estimatedDays;
  final AppCurrency currency;
  final List<int> coverImageIds;
  final List<String> coverImages;
  final List<EditVisaPackageTierDraftInput> tiers;
}

class EditVisaPackageController extends Notifier<EditVisaPackageState> {
  @override
  EditVisaPackageState build() => const EditVisaPackageState();

  Future<void> loadServiceTags({bool force = false}) async {
    if (state.isLoadingServiceTags) {
      return;
    }
    if (state.hasLoadedServiceTags && !force) {
      return;
    }

    state = state.copyWith(isLoadingServiceTags: true, serviceTagsError: null);

    try {
      final List<TagItemVO> tags = await ref
          .read(tagDictionaryCacheControllerProvider)
          .getTagsForCategory(TagCategory.service);
      state = state.copyWith(
        serviceTags: tags,
        hasLoadedServiceTags: true,
        isLoadingServiceTags: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingServiceTags: false,
        serviceTagsError: '签证编辑.包含服务标签加载失败'.tr(),
      );
    }
  }

  void setCountryCode(String code) {
    state = state.copyWith(selectedCountryCode: code);
  }

  void setVisaTypeCode(String code) {
    state = state.copyWith(selectedVisaTypeCode: code);
  }

  void setCurrency(AppCurrency currency) {
    state = state.copyWith(selectedCurrency: currency);
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }

  String tagLabel(TagItemVO tag) {
    if (tag.tagNameZh.trim().isNotEmpty) {
      return tag.tagNameZh.trim();
    }
    return tag.tagNameEn.trim();
  }

  Future<void> saveDraft(
    EditVisaPackageFormDraft draft, {
    int? packageId,
  }) async {
    await _submit(draft, isDraft: true, packageId: packageId);
  }

  Future<void> publish(EditVisaPackageFormDraft draft, {int? packageId}) async {
    await _submit(draft, isDraft: false, packageId: packageId);
  }

  Future<void> _submit(
    EditVisaPackageFormDraft draft, {
    required bool isDraft,
    int? packageId,
  }) async {
    if (state.isSavingDraft || state.isPublishing) {
      return;
    }

    final CreateVisaPackageBO? request = _buildRequest(draft, isDraft: isDraft);
    if (request == null) {
      return;
    }

    state = state.copyWith(
      isSavingDraft: isDraft ? true : false,
      isPublishing: isDraft ? false : true,
    );

    try {
      if (packageId == null) {
        await ref
            .read(visaPackageServiceProvider)
            .createPackage(request: request);
      } else {
        await ref
            .read(visaPackageServiceProvider)
            .updatePackage(packageId: packageId, request: request);
      }
      _invalidateMyPackageLists();
      state = state.copyWith(
        isSavingDraft: false,
        isPublishing: false,
        submitSuccessId: state.submitSuccessId + 1,
      );
      _emitFeedback(
        packageId == null
            ? (isDraft ? '签证编辑.草稿保存成功'.tr() : '签证编辑.签证套餐发布成功'.tr())
            : (isDraft ? '签证编辑.草稿更新成功'.tr() : '签证编辑.签证套餐更新成功'.tr()),
      );
    } catch (_) {
      state = state.copyWith(isSavingDraft: false, isPublishing: false);
      _emitFeedback(
        packageId == null
            ? (isDraft ? '签证编辑.草稿保存失败'.tr() : '签证编辑.签证套餐发布失败'.tr())
            : (isDraft ? '签证编辑.草稿更新失败'.tr() : '签证编辑.签证套餐更新失败'.tr()),
        isError: true,
      );
    }
  }

  CreateVisaPackageBO? _buildRequest(
    EditVisaPackageFormDraft draft, {
    required bool isDraft,
  }) {
    final String name = draft.name.trim();
    if (name.isEmpty) {
      _emitFeedback('签证编辑.请填写套餐总名称'.tr(), isError: true);
      return null;
    }

    final String? countryCode = state.selectedCountryCode;
    if (countryCode == null || countryCode.isEmpty) {
      _emitFeedback('签证编辑.请选择服务国家'.tr(), isError: true);
      return null;
    }

    final String? visaTypeCode = state.selectedVisaTypeCode;
    if (visaTypeCode == null || visaTypeCode.isEmpty) {
      _emitFeedback('签证编辑.请选择签证类型'.tr(), isError: true);
      return null;
    }

    final int? estimatedDays = int.tryParse(draft.estimatedDays.trim());
    if (estimatedDays == null || estimatedDays <= 0) {
      _emitFeedback('签证编辑.请填写正确的预计周期'.tr(), isError: true);
      return null;
    }

    if (draft.tiers.isEmpty) {
      _emitFeedback('签证编辑.请至少添加一个套餐档位'.tr(), isError: true);
      return null;
    }

    final List<TierBO> tiers = <TierBO>[];
    for (int index = 0; index < draft.tiers.length; index++) {
      final EditVisaPackageTierDraftInput tier = draft.tiers[index];
      final String tierName = tier.name.trim();
      if (tierName.isEmpty) {
        _emitFeedback(
          '签证编辑.请填写档位名称'.tr(
            namedArgs: <String, String>{'index': (index + 1).toString()},
          ),
          isError: true,
        );
        return null;
      }

      final double? price = double.tryParse(tier.price.trim());
      if (price == null || price <= 0) {
        _emitFeedback(
          '签证编辑.请填写档位正确价格'.tr(
            namedArgs: <String, String>{'index': (index + 1).toString()},
          ),
          isError: true,
        );
        return null;
      }

      final List<String> selectedServices = tier.selectedServiceTagCodes
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      final List<String> customServices = tier.customServices
          .map((String item) => item.trim())
          .where((String item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false);
      if (selectedServices.isEmpty && customServices.isEmpty) {
        _emitFeedback(
          '签证编辑.请至少选择一个包含服务'.tr(
            namedArgs: <String, String>{'index': (index + 1).toString()},
          ),
          isError: true,
        );
        return null;
      }

      final List<MaterialBO> materials = <MaterialBO>[];
      if (tier.showMaterials) {
        for (
          int materialIndex = 0;
          materialIndex < tier.materials.length;
          materialIndex++
        ) {
          final EditVisaPackageMaterialDraftInput material =
              tier.materials[materialIndex];
          final String materialName = material.name.trim();
          final String materialDescription = material.description.trim();
          if (materialName.isEmpty && materialDescription.isEmpty) {
            continue;
          }
          if (materialName.isEmpty) {
            _emitFeedback(
              '签证编辑.请填写材料名称'.tr(
                namedArgs: <String, String>{
                  'tierIndex': (index + 1).toString(),
                  'materialIndex': (materialIndex + 1).toString(),
                },
              ),
              isError: true,
            );
            return null;
          }
          materials.add(
            MaterialBO(
              name: materialName,
              description: materialDescription,
              isRequired: material.isRequired,
              sortOrder: materials.length + 1,
              exampleFileIds: material.exampleFileIds,
            ),
          );
        }
      }

      tiers.add(
        TierBO(
          tierId: tier.tierId,
          name: tierName,
          price: price,
          services: selectedServices,
          customServices: customServices,
          description: tier.description.trim(),
          showMaterials: tier.showMaterials,
          sortOrder: index + 1,
          materials: materials,
        ),
      );
    }

    final List<int> coverImageIds = draft.coverImageIds
        .take(1)
        .toList(growable: false);
    final List<String> coverImages = draft.coverImages
        .take(1)
        .toList(growable: false);

    return CreateVisaPackageBO(
      name: name,
      targetCountry: countryCode,
      visaType: visaTypeCode,
      estimatedDays: estimatedDays,
      currency: draft.currency.apiValue,
      coverImageIds: coverImageIds,
      coverImages: coverImages,
      tiers: tiers,
      isDraft: isDraft,
    );
  }

  void _emitFeedback(String message, {bool isError = false}) {
    state = state.copyWith(
      feedbackMessage: message,
      feedbackIsError: isError,
      feedbackId: state.feedbackId + 1,
    );
  }

  void _invalidateMyPackageLists() {
    ref.invalidate(myVisaPackageListProvider('active'));
    ref.invalidate(myVisaPackageListProvider('inactive'));
    ref.invalidate(myVisaPackageListProvider('draft'));
  }
}
