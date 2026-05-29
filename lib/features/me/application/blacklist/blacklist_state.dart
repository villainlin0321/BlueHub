import '../../data/user_models.dart';

const Object _errorMessageSentinel = Object();
const Object _feedbackMessageSentinel = Object();

class BlacklistState {
  const BlacklistState({
    this.items = const <UserVO>[],
    this.isLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.currentPage = 0,
    this.totalCount = 0,
    this.hasNext = false,
    this.removingUserIds = const <int>{},
    this.feedbackMessage,
    this.feedbackId = 0,
    this.removedUserVersion = 0,
  });

  final List<UserVO> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final int currentPage;
  final int totalCount;
  final bool hasNext;
  final Set<int> removingUserIds;
  final String? feedbackMessage;
  final int feedbackId;
  final int removedUserVersion;

  BlacklistState copyWith({
    List<UserVO>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    Object? errorMessage = _errorMessageSentinel,
    int? currentPage,
    int? totalCount,
    bool? hasNext,
    Set<int>? removingUserIds,
    Object? feedbackMessage = _feedbackMessageSentinel,
    int? feedbackId,
    int? removedUserVersion,
  }) {
    return BlacklistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: identical(errorMessage, _errorMessageSentinel)
          ? this.errorMessage
          : errorMessage as String?,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasNext: hasNext ?? this.hasNext,
      removingUserIds: removingUserIds ?? this.removingUserIds,
      feedbackMessage: identical(feedbackMessage, _feedbackMessageSentinel)
          ? this.feedbackMessage
          : feedbackMessage as String?,
      feedbackId: feedbackId ?? this.feedbackId,
      removedUserVersion: removedUserVersion ?? this.removedUserVersion,
    );
  }
}
