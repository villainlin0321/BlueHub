import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/data/config_models.dart';
import '../../../config/data/config_providers.dart';
import '../../../../shared/network/services/config_service.dart';
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
  });

  final String name;
  final String description;
  final bool isRequired;
}

class EditVisaPackageTierDraftInput {
  const EditVisaPackageTierDraftInput({
    required this.name,
    required this.price,
    required this.description,
    required this.showMaterials,
    required this.selectedServiceTagCodes,
    required this.customServices,
    required this.materials,
  });

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
    required this.tiers,
  });

  final String name;
  final String estimatedDays;
  final List<EditVisaPackageTierDraftInput> tiers;
}

class EditVisaPackageController extends Notifier<EditVisaPackageState> {
  static const String _currency = 'CNY';

  @override
  EditVisaPackageState build() => const EditVisaPackageState();

  Future<void> loadServiceTags({bool force = false}) async {
    if (state.isLoadingServiceTags) {
      return;
    }
    if (state.hasLoadedServiceTags && !force) {
      return;
    }

    state = state.copyWith(
      isLoadingServiceTags: true,
      serviceTagsError: null,
    );

    try {
      final TagDictVO response = await ref
          .read(configServiceProvider)
          .getTags();
      final List<TagItemVO> tags = List<TagItemVO>.from(
        response.tags[TagCategory.service.value] ?? const <TagItemVO>[],
      )..sort((TagItemVO a, TagItemVO b) => a.sortOrder.compareTo(b.sortOrder));
      state = state.copyWith(
        serviceTags: tags,
        hasLoadedServiceTags: true,
        isLoadingServiceTags: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingServiceTags: false,
        serviceTagsError: '包含服务标签加载失败',
      );
    }
  }

  void setCountryCode(String code) {
    state = state.copyWith(selectedCountryCode: code);
  }

  void setVisaTypeCode(String code) {
    state = state.copyWith(selectedVisaTypeCode: code);
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

  Future<void> saveDraft(EditVisaPackageFormDraft draft) async {
    await _submit(draft, isDraft: true);
  }

  Future<void> publish(EditVisaPackageFormDraft draft) async {
    await _submit(draft, isDraft: false);
  }

  Future<void> _submit(
    EditVisaPackageFormDraft draft, {
    required bool isDraft,
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
      await ref.read(visaPackageServiceProvider).createPackage(request: request);
      state = state.copyWith(
        isSavingDraft: false,
        isPublishing: false,
        submitSuccessId: state.submitSuccessId + 1,
      );
      _emitFeedback(isDraft ? '草稿保存成功' : '签证套餐发布成功');
    } catch (_) {
      state = state.copyWith(isSavingDraft: false, isPublishing: false);
      _emitFeedback(isDraft ? '草稿保存失败，请稍后重试' : '签证套餐发布失败，请稍后重试', isError: true);
    }
  }

  CreateVisaPackageBO? _buildRequest(
    EditVisaPackageFormDraft draft, {
    required bool isDraft,
  }) {
    final String name = draft.name.trim();
    if (name.isEmpty) {
      _emitFeedback('请填写套餐总名称', isError: true);
      return null;
    }

    final String? countryCode = state.selectedCountryCode;
    if (countryCode == null || countryCode.isEmpty) {
      _emitFeedback('请选择服务国家', isError: true);
      return null;
    }

    final String? visaTypeCode = state.selectedVisaTypeCode;
    if (visaTypeCode == null || visaTypeCode.isEmpty) {
      _emitFeedback('请选择签证类型', isError: true);
      return null;
    }

    final int? estimatedDays = int.tryParse(draft.estimatedDays.trim());
    if (estimatedDays == null || estimatedDays <= 0) {
      _emitFeedback('请填写正确的预计周期', isError: true);
      return null;
    }

    if (draft.tiers.isEmpty) {
      _emitFeedback('请至少添加一个套餐档位', isError: true);
      return null;
    }

    final List<TierBO> tiers = <TierBO>[];
    for (int index = 0; index < draft.tiers.length; index++) {
      final EditVisaPackageTierDraftInput tier = draft.tiers[index];
      final String tierName = tier.name.trim();
      if (tierName.isEmpty) {
        _emitFeedback('请填写第${index + 1}个档位名称', isError: true);
        return null;
      }

      final double? price = double.tryParse(tier.price.trim());
      if (price == null || price <= 0) {
        _emitFeedback('请填写第${index + 1}个档位的正确价格', isError: true);
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
        _emitFeedback('请至少为第${index + 1}个档位选择一个包含服务', isError: true);
        return null;
      }

      final List<MaterialBO> materials = <MaterialBO>[];
      if (tier.showMaterials) {
        for (int materialIndex = 0; materialIndex < tier.materials.length; materialIndex++) {
          final EditVisaPackageMaterialDraftInput material =
              tier.materials[materialIndex];
          final String materialName = material.name.trim();
          final String materialDescription = material.description.trim();
          if (materialName.isEmpty && materialDescription.isEmpty) {
            continue;
          }
          if (materialName.isEmpty) {
            _emitFeedback('请填写第${index + 1}个档位中材料${materialIndex + 1}的名称', isError: true);
            return null;
          }
          materials.add(
            MaterialBO(
              name: materialName,
              description: materialDescription,
              isRequired: material.isRequired,
              sortOrder: materials.length + 1,
            ),
          );
        }
      }

      tiers.add(
        TierBO(
          tierId: 0,
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

    return CreateVisaPackageBO(
      name: name,
      targetCountry: countryCode,
      visaType: visaTypeCode,
      estimatedDays: estimatedDays,
      currency: _currency,
      coverImageIds: const <int>[],
      coverImages: const <String>[],
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
}
