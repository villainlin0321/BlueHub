const Object _feedbackSentinel = Object();

class SelectRoleState {
  const SelectRoleState({
    this.selectedRoleId,
    this.isSubmitting = false,
    this.feedbackMessage,
    this.feedbackIsError = false,
    this.feedbackId = 0,
  });

  final String? selectedRoleId;
  final bool isSubmitting;
  final String? feedbackMessage;
  final bool feedbackIsError;
  final int feedbackId;

  SelectRoleState copyWith({
    Object? selectedRoleId = _feedbackSentinel,
    bool? isSubmitting,
    Object? feedbackMessage = _feedbackSentinel,
    bool? feedbackIsError,
    int? feedbackId,
  }) {
    return SelectRoleState(
      selectedRoleId: identical(selectedRoleId, _feedbackSentinel)
          ? this.selectedRoleId
          : selectedRoleId as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      feedbackMessage: identical(feedbackMessage, _feedbackSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackIsError: feedbackIsError ?? this.feedbackIsError,
      feedbackId: feedbackId ?? this.feedbackId,
    );
  }
}
