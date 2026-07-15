import 'package:europepass/shared/network/models/talent_models.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/services/talent_service.dart';

final talentServiceProvider = Provider<TalentService>((ref) {
  return TalentService(apiClient: ref.watch(apiClientProvider));
});

final talentListProvider = FutureProvider.autoDispose
    .family<PageResult<TalentVO>, TalentListQuery>((ref, query) async {
      final service = ref.watch(talentServiceProvider);
      return service.listTalents(
        keyword: query.keyword,
        country: query.country,
        position: query.position,
        sort: query.sort,
        page: query.page,
        pageSize: query.pageSize,
      );
    });

class TalentListQuery {
  const TalentListQuery({
    this.keyword,
    this.country,
    this.position,
    this.sort,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? keyword;
  final String? country;
  final String? position;
  final String? sort;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TalentListQuery &&
            runtimeType == other.runtimeType &&
            keyword == other.keyword &&
            country == other.country &&
            position == other.position &&
            sort == other.sort &&
            page == other.page &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode =>
      Object.hash(keyword, country, position, sort, page, pageSize);
}
