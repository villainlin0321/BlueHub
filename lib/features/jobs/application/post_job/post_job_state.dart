import '../../../config/data/config_models.dart';
import '../../../../shared/models/app_currency.dart';

const Object _feedbackSentinel = Object();
const Object _requirementTagsErrorSentinel = Object();

class PostJobState {
  const PostJobState({
    this.selectedJobType = 'any',
    this.selectedSalaryUnit = 'month',
    this.selectedSalaryCurrency = AppCurrency.eur,
    this.requirementTags = const <TagItemVO>[],
    this.selectedRequirementTagCodes = const <String>{},
    this.customTags = const <String>[],
    this.hasLoadedRequirementTags = false,
    this.isLoadingRequirementTags = false,
    this.requirementTagsError,
    this.isPublishing = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackId = 0,
    this.publishSuccessId = 0,
  });

  final String selectedJobType;
  final String selectedSalaryUnit;
  final AppCurrency selectedSalaryCurrency;
  final List<TagItemVO> requirementTags;
  final Set<String> selectedRequirementTagCodes;
  final List<String> customTags;
  final bool hasLoadedRequirementTags;
  final bool isLoadingRequirementTags;
  final String? requirementTagsError;
  final bool isPublishing;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackId;
  final int publishSuccessId;

  PostJobState copyWith({
    String? selectedJobType,
    String? selectedSalaryUnit,
    AppCurrency? selectedSalaryCurrency,
    List<TagItemVO>? requirementTags,
    Set<String>? selectedRequirementTagCodes,
    List<String>? customTags,
    bool? hasLoadedRequirementTags,
    bool? isLoadingRequirementTags,
    Object? requirementTagsError = _requirementTagsErrorSentinel,
    bool? isPublishing,
    Object? feedbackMessage = _feedbackSentinel,
    bool? feedbackIsError,
    int? feedbackId,
    int? publishSuccessId,
  }) {
    return PostJobState(
      selectedJobType: selectedJobType ?? this.selectedJobType,
      selectedSalaryUnit: selectedSalaryUnit ?? this.selectedSalaryUnit,
      selectedSalaryCurrency:
          selectedSalaryCurrency ?? this.selectedSalaryCurrency,
      requirementTags: requirementTags ?? this.requirementTags,
      selectedRequirementTagCodes:
          selectedRequirementTagCodes ?? this.selectedRequirementTagCodes,
      customTags: customTags ?? this.customTags,
      hasLoadedRequirementTags:
          hasLoadedRequirementTags ?? this.hasLoadedRequirementTags,
      isLoadingRequirementTags:
          isLoadingRequirementTags ?? this.isLoadingRequirementTags,
      requirementTagsError:
          identical(requirementTagsError, _requirementTagsErrorSentinel)
          ? this.requirementTagsError
          : requirementTagsError as String?,
      isPublishing: isPublishing ?? this.isPublishing,
      feedbackMessage: identical(feedbackMessage, _feedbackSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackId: feedbackId ?? this.feedbackId,
      publishSuccessId: publishSuccessId ?? this.publishSuccessId,
    );
  }
}
