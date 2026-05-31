class VisaProviderSearchState {
  const VisaProviderSearchState({
    this.historyKeywords = const <String>[],
    this.submittedKeyword,
    this.isLoadingHistory = false,
    this.isClearingHistory = false,
    this.feedbackMessage,
    this.feedbackId = 0,
  });

  static const Object _sentinel = Object();

  final List<String> historyKeywords;
  final String? submittedKeyword;
  final bool isLoadingHistory;
  final bool isClearingHistory;
  final String? feedbackMessage;
  final int feedbackId;

  bool get isShowingResults => (submittedKeyword ?? '').trim().isNotEmpty;

  VisaProviderSearchState copyWith({
    List<String>? historyKeywords,
    Object? submittedKeyword = _sentinel,
    bool? isLoadingHistory,
    bool? isClearingHistory,
    Object? feedbackMessage = _sentinel,
    int? feedbackId,
  }) {
    return VisaProviderSearchState(
      historyKeywords: historyKeywords ?? this.historyKeywords,
      submittedKeyword: identical(submittedKeyword, _sentinel)
          ? this.submittedKeyword
          : submittedKeyword as String?,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isClearingHistory: isClearingHistory ?? this.isClearingHistory,
      feedbackMessage: identical(feedbackMessage, _sentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackId: feedbackId ?? this.feedbackId,
    );
  }
}
