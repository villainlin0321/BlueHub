import '../../../config/data/config_models.dart';

const Object _feedbackSentinel = Object();
const Object _serviceTagsErrorSentinel = Object();

class EditVisaPackageState {
  const EditVisaPackageState({
    this.selectedCountryCode,
    this.selectedVisaTypeCode,
    this.serviceTags = const <TagItemVO>[],
    this.hasLoadedServiceTags = false,
    this.isLoadingServiceTags = false,
    this.serviceTagsError,
    this.isSavingDraft = false,
    this.isPublishing = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackId = 0,
    this.submitSuccessId = 0,
  });

  final String? selectedCountryCode;
  final String? selectedVisaTypeCode;
  final List<TagItemVO> serviceTags;
  final bool hasLoadedServiceTags;
  final bool isLoadingServiceTags;
  final String? serviceTagsError;
  final bool isSavingDraft;
  final bool isPublishing;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackId;
  final int submitSuccessId;

  EditVisaPackageState copyWith({
    Object? selectedCountryCode = _feedbackSentinel,
    Object? selectedVisaTypeCode = _feedbackSentinel,
    List<TagItemVO>? serviceTags,
    bool? hasLoadedServiceTags,
    bool? isLoadingServiceTags,
    Object? serviceTagsError = _serviceTagsErrorSentinel,
    bool? isSavingDraft,
    bool? isPublishing,
    Object? feedbackMessage = _feedbackSentinel,
    bool? feedbackIsError,
    int? feedbackId,
    int? submitSuccessId,
  }) {
    return EditVisaPackageState(
      selectedCountryCode: identical(selectedCountryCode, _feedbackSentinel)
          ? this.selectedCountryCode
          : selectedCountryCode as String?,
      selectedVisaTypeCode: identical(selectedVisaTypeCode, _feedbackSentinel)
          ? this.selectedVisaTypeCode
          : selectedVisaTypeCode as String?,
      serviceTags: serviceTags ?? this.serviceTags,
      hasLoadedServiceTags: hasLoadedServiceTags ?? this.hasLoadedServiceTags,
      isLoadingServiceTags: isLoadingServiceTags ?? this.isLoadingServiceTags,
      serviceTagsError:
          identical(serviceTagsError, _serviceTagsErrorSentinel)
              ? this.serviceTagsError
              : serviceTagsError as String?,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isPublishing: isPublishing ?? this.isPublishing,
      feedbackMessage: identical(feedbackMessage, _feedbackSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackId: feedbackId ?? this.feedbackId,
      submitSuccessId: submitSuccessId ?? this.submitSuccessId,
    );
  }
}
