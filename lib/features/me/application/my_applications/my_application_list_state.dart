import '../../data/my_applications_models.dart';

const Object _errorMessageSentinel = Object();

class MyApplicationListState {
  const MyApplicationListState({
    this.items = const <MyApplicationItem>[],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.hasLoadedOnce = false,
    this.nextPage = 1,
    this.errorMessage,
  });

  final List<MyApplicationItem> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasLoadedOnce;
  final int nextPage;
  final String? errorMessage;

  MyApplicationListState copyWith({
    List<MyApplicationItem>? items,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    bool? hasLoadedOnce,
    int? nextPage,
    Object? errorMessage = _errorMessageSentinel,
  }) {
    return MyApplicationListState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
      nextPage: nextPage ?? this.nextPage,
      errorMessage: identical(errorMessage, _errorMessageSentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
