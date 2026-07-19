import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/network/api_error_feedback.dart';
import '../../data/application_models.dart';
import '../../data/application_providers.dart';
import '../../../shell/application/shell_role_provider.dart';
import 'company_application_list_state.dart';

final companyApplicationListsControllerProvider =
    NotifierProvider<
      CompanyApplicationListsController,
      Map<String, CompanyApplicationListState>
    >(CompanyApplicationListsController.new);

String buildCompanyApplicationListStateKey({
  required String status,
  int? jobId,
}) {
  return '$status::${jobId ?? 'all'}';
}

class CompanyApplicationListsController
    extends Notifier<Map<String, CompanyApplicationListState>> {
  static const int _pageSize = 10;

  @override
  Map<String, CompanyApplicationListState> build() {
    ref.watch(shellRoleProvider);
    return const <String, CompanyApplicationListState>{};
  }

  CompanyApplicationListState getState(String status, {int? jobId}) {
    final String key = buildCompanyApplicationListStateKey(
      status: status,
      jobId: jobId,
    );
    return state[key] ?? const CompanyApplicationListState();
  }

  Future<void> refreshStatuses({
    required List<String> statuses,
    int? jobId,
  }) async {
    await Future.wait(
      statuses.map((String status) {
        return loadInitial(status: status, jobId: jobId, force: true);
      }),
    );
  }

  Future<bool> loadInitial({
    required String status,
    int? jobId,
    bool force = false,
  }) async {
    final CompanyApplicationListState current = getState(status, jobId: jobId);
    if (current.isInitialLoading) {
      return false;
    }
    if (current.hasLoadedOnce && !force) {
      return true;
    }

    _setStatus(
      status,
      current.copyWith(isInitialLoading: true, errorMessage: null),
      jobId: jobId,
    );

    try {
      final ListPagePayload payload = await _fetchPage(
        status: status,
        jobId: jobId,
        page: 1,
      );
      _setStatus(status, payload.state, jobId: jobId);
      return true;
    } catch (error) {
      _setStatus(
        status,
        getState(status, jobId: jobId).copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasLoadedOnce: true,
          errorMessage: _normalizeError(error),
        ),
        jobId: jobId,
      );
      return false;
    }
  }

  Future<bool> refresh({required String status, int? jobId}) async {
    final CompanyApplicationListState current = getState(status, jobId: jobId);
    if (current.isRefreshing || current.isInitialLoading) {
      return false;
    }

    _setStatus(
      status,
      current.copyWith(isRefreshing: true, errorMessage: null),
      jobId: jobId,
    );

    try {
      final ListPagePayload payload = await _fetchPage(
        status: status,
        jobId: jobId,
        page: 1,
      );
      _setStatus(
        status,
        payload.state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
        ),
        jobId: jobId,
      );
      return true;
    } catch (error) {
      _setStatus(
        status,
        getState(
          status,
          jobId: jobId,
        ).copyWith(isRefreshing: false, errorMessage: _normalizeError(error)),
        jobId: jobId,
      );
      return false;
    }
  }

  Future<bool> loadMore({required String status, int? jobId}) async {
    final CompanyApplicationListState current = getState(status, jobId: jobId);
    if (current.isInitialLoading ||
        current.isRefreshing ||
        current.isLoadingMore ||
        !current.hasMore) {
      return false;
    }

    _setStatus(
      status,
      current.copyWith(isLoadingMore: true, errorMessage: null),
      jobId: jobId,
    );

    try {
      final ListPagePayload payload = await _fetchPage(
        status: status,
        jobId: jobId,
        page: current.nextPage,
      );
      _setStatus(
        status,
        current.copyWith(
          applications: <ApplicationVO>[
            ...current.applications,
            ...payload.state.applications,
          ],
          isLoadingMore: false,
          hasLoadedOnce: true,
          nextPage: payload.state.nextPage,
          hasMore: payload.state.hasMore,
          errorMessage: null,
        ),
        jobId: jobId,
      );
      return true;
    } catch (error) {
      _setStatus(
        status,
        getState(
          status,
          jobId: jobId,
        ).copyWith(isLoadingMore: false, errorMessage: _normalizeError(error)),
        jobId: jobId,
      );
      return false;
    }
  }

  Future<ApplicationStatusUpdateResult> updateApplicationStatus({
    required String sourceStatus,
    int? jobId,
    required int applicationId,
    required EmployerApplicationUpdateStatus nextStatus,
    String remark = '',
  }) async {
    final CompanyApplicationListState current = getState(
      sourceStatus,
      jobId: jobId,
    );
    if (current.processingActions.containsKey(applicationId)) {
      return ApplicationStatusUpdateResult(
        success: false,
        message: '应聘管理.正在处理中请稍候'.tr(),
      );
    }

    _setStatus(
      sourceStatus,
      current.copyWith(
        processingActions: <int, EmployerApplicationUpdateStatus>{
          ...current.processingActions,
          applicationId: nextStatus,
        },
        errorMessage: null,
      ),
      jobId: jobId,
    );

    try {
      await ref
          .read(applicationServiceProvider)
          .updateStatus(
            applicationId: applicationId,
            request: UpdateApplicationStatusBO.fromStatus(
              status: nextStatus,
              remark: remark.trim(),
            ),
          );

      _removeApplicationFromStatus(
        sourceStatus: sourceStatus,
        jobId: jobId,
        applicationId: applicationId,
      );

      await _refreshLoadedStatus(sourceStatus, jobId: jobId);
      final String? targetStatus = nextStatus.targetListStatus?.value;
      if (targetStatus != null && targetStatus != sourceStatus) {
        await _refreshLoadedStatus(targetStatus, jobId: jobId);
      }

      return ApplicationStatusUpdateResult(
        success: true,
        message: '应聘管理.操作成功'.tr(
          namedArgs: <String, String>{'action': nextStatus.labelKey.tr()},
        ),
      );
    } catch (error) {
      final CompanyApplicationListState latest = getState(
        sourceStatus,
        jobId: jobId,
      );
      final Map<int, EmployerApplicationUpdateStatus> processingActions =
          <int, EmployerApplicationUpdateStatus>{...latest.processingActions}
            ..remove(applicationId);
      _setStatus(
        sourceStatus,
        latest.copyWith(
          processingActions: processingActions,
          errorMessage: _normalizeError(error),
        ),
        jobId: jobId,
      );
      return ApplicationStatusUpdateResult(
        success: false,
        message: _normalizeError(error),
      );
    }
  }

  Future<ListPagePayload> _fetchPage({
    required String status,
    int? jobId,
    required int page,
  }) async {
    final response = await ref
        .read(applicationServiceProvider)
        .listJobApplications(
          jobId: jobId,
          page: page,
          pageSize: _pageSize,
          status: status,
        );
    return ListPagePayload(
      CompanyApplicationListState(
        applications: response.list,
        hasLoadedOnce: true,
        isInitialLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        nextPage: response.pagination.page + 1,
        hasMore: response.pagination.hasNext,
        errorMessage: null,
      ),
    );
  }

  void _setStatus(
    String status,
    CompanyApplicationListState nextState, {
    int? jobId,
  }) {
    final String key = buildCompanyApplicationListStateKey(
      status: status,
      jobId: jobId,
    );
    state = <String, CompanyApplicationListState>{...state, key: nextState};
  }

  void _removeApplicationFromStatus({
    required String sourceStatus,
    int? jobId,
    required int applicationId,
  }) {
    final CompanyApplicationListState current = getState(
      sourceStatus,
      jobId: jobId,
    );
    final Map<int, EmployerApplicationUpdateStatus> processingActions =
        <int, EmployerApplicationUpdateStatus>{...current.processingActions}
          ..remove(applicationId);
    _setStatus(
      sourceStatus,
      current.copyWith(
        applications: current.applications
            .where((ApplicationVO item) => item.applicationId != applicationId)
            .toList(growable: false),
        processingActions: processingActions,
      ),
      jobId: jobId,
    );
  }

  Future<void> _refreshLoadedStatus(String status, {int? jobId}) async {
    final CompanyApplicationListState current = getState(status, jobId: jobId);
    if (!current.hasLoadedOnce) {
      return;
    }
    await refresh(status: status, jobId: jobId);
  }

  String _normalizeError(Object error) {
    return ApiErrorFeedback.resolveMessage(error, fallback: '应聘管理.加载失败'.tr());
  }
}

class ListPagePayload {
  const ListPagePayload(this.state);

  final CompanyApplicationListState state;
}

class ApplicationStatusUpdateResult {
  const ApplicationStatusUpdateResult({
    required this.success,
    required this.message,
  });

  final bool success;
  final String message;
}
