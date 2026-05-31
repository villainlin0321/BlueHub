import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/visa_provider_search_history_store.dart';
import 'visa_provider_search_state.dart';

final visaProviderSearchControllerProvider =
    NotifierProvider<VisaProviderSearchController, VisaProviderSearchState>(
      VisaProviderSearchController.new,
    );

class VisaProviderSearchController extends Notifier<VisaProviderSearchState> {
  @override
  VisaProviderSearchState build() => const VisaProviderSearchState();

  VisaProviderSearchHistoryStore get _historyStore =>
      ref.read(visaProviderSearchHistoryStoreProvider);

  Future<void> loadHistory() async {
    state = state.copyWith(isLoadingHistory: true, feedbackMessage: null);
    try {
      final List<String> historyKeywords = _historyStore.loadHistory();
      state = state.copyWith(
        isLoadingHistory: false,
        historyKeywords: historyKeywords,
      );
    } catch (_) {
      state = state.copyWith(
        isLoadingHistory: false,
        feedbackMessage: '签证搜索.历史记录加载失败'.tr(),
        feedbackId: state.feedbackId + 1,
      );
    }
  }

  void handleInputChanged(String value) {
    if (value.trim().isNotEmpty || !state.isShowingResults) {
      return;
    }
    state = state.copyWith(submittedKeyword: null);
  }

  Future<void> submitKeyword(String keyword) async {
    final String normalized = keyword.trim();
    if (normalized.isEmpty) {
      state = state.copyWith(submittedKeyword: null);
      return;
    }

    try {
      final List<String> historyKeywords = await _historyStore.saveKeyword(
        normalized,
      );
      state = state.copyWith(
        historyKeywords: historyKeywords,
        submittedKeyword: normalized,
      );
    } catch (_) {
      state = state.copyWith(
        feedbackMessage: '签证搜索.历史记录保存失败'.tr(),
        feedbackId: state.feedbackId + 1,
      );
    }
  }

  Future<void> clearHistory() async {
    if (state.isClearingHistory) {
      return;
    }
    state = state.copyWith(isClearingHistory: true, feedbackMessage: null);
    try {
      await _historyStore.clear();
      state = state.copyWith(
        isClearingHistory: false,
        historyKeywords: const <String>[],
      );
    } catch (_) {
      state = state.copyWith(
        isClearingHistory: false,
        feedbackMessage: '签证搜索.清空历史记录失败'.tr(),
        feedbackId: state.feedbackId + 1,
      );
    }
  }

  void clearFeedback() {
    if (state.feedbackMessage == null) {
      return;
    }
    state = state.copyWith(feedbackMessage: null);
  }
}
