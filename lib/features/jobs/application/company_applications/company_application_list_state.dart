import '../../data/application_models.dart';

const Object _errorMessageSentinel = Object();

class CompanyApplicationListState {
  const CompanyApplicationListState({
    this.applications = const <ApplicationVO>[],
    this.processingActions = const <int, EmployerApplicationUpdateStatus>{},
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.hasLoadedOnce = false,
    this.nextPage = 1,
    this.errorMessage,
  });

  final List<ApplicationVO> applications;
  final Map<int, EmployerApplicationUpdateStatus> processingActions;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasMore;
  final bool hasLoadedOnce;
  final int nextPage;
  final String? errorMessage;

  CompanyApplicationListState copyWith({
    List<ApplicationVO>? applications,
    Map<int, EmployerApplicationUpdateStatus>? processingActions,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasMore,
    bool? hasLoadedOnce,
    int? nextPage,
    Object? errorMessage = _errorMessageSentinel,
  }) {
    return CompanyApplicationListState(
      applications: applications ?? this.applications,
      processingActions: processingActions ?? this.processingActions,
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
