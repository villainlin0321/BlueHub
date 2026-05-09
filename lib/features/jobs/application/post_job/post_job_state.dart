import '../../../config/data/config_models.dart';

const Object _feedbackSentinel = Object();
const Object _requirementTagsErrorSentinel = Object();

class PostJobState {
  const PostJobState({
    this.selectedJobType = '不限',
    this.selectedSalaryUnit = '月薪',
    this.requirementTags = const <TagItemVO>[],
    this.selectedRequirementTagCodes = const <String>{},
    this.customTags = const <String>[],
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
  final List<TagItemVO> requirementTags;
  final Set<String> selectedRequirementTagCodes;
  final List<String> customTags;
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
    List<TagItemVO>? requirementTags,
    Set<String>? selectedRequirementTagCodes,
    List<String>? customTags,
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
      requirementTags: requirementTags ?? this.requirementTags,
      selectedRequirementTagCodes:
          selectedRequirementTagCodes ?? this.selectedRequirementTagCodes,
      customTags: customTags ?? this.customTags,
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
