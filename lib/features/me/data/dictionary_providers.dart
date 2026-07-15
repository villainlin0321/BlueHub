import 'package:europepass/shared/network/models/dictionary_models.dart';
import 'package:europepass/shared/network/page_result.dart';
import 'package:europepass/shared/network/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/services/country_service.dart';
import '../../../shared/network/services/position_service.dart';
import '../../../shared/network/services/school_service.dart';

final countryServiceProvider = Provider<CountryService>((ref) {
  return CountryService(apiClient: ref.watch(apiClientProvider));
});

final schoolServiceProvider = Provider<SchoolService>((ref) {
  return SchoolService(apiClient: ref.watch(apiClientProvider));
});

final positionServiceProvider = Provider<PositionService>((ref) {
  return PositionService(apiClient: ref.watch(apiClientProvider));
});

final schoolSearchProvider = FutureProvider.autoDispose
    .family<PageResult<SchoolVO>, SchoolSearchQuery>((ref, query) async {
      final service = ref.watch(schoolServiceProvider);
      return service.searchSchools(
        keyword: query.keyword,
        country: query.country,
        page: query.page,
        pageSize: query.pageSize,
      );
    });

final countrySearchProvider = FutureProvider.autoDispose
    .family<PageResult<CountryVO>, CountrySearchQuery>((ref, query) async {
      final service = ref.watch(countryServiceProvider);
      return service.searchCountries(
        keyword: query.keyword,
        page: query.page,
        pageSize: query.pageSize,
      );
    });

final positionTreeProvider = FutureProvider.autoDispose
    .family<List<PositionCategoryVO>, String?>((ref, keyword) async {
      final service = ref.watch(positionServiceProvider);
      return service.listPositionTree(keyword: keyword);
    });

class SchoolSearchQuery {
  const SchoolSearchQuery({
    this.keyword,
    this.country,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? keyword;
  final String? country;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SchoolSearchQuery &&
            runtimeType == other.runtimeType &&
            keyword == other.keyword &&
            country == other.country &&
            page == other.page &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode => Object.hash(keyword, country, page, pageSize);
}

class CountrySearchQuery {
  const CountrySearchQuery({this.keyword, this.page = 1, this.pageSize = 50});

  final String? keyword;
  final int page;
  final int pageSize;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CountrySearchQuery &&
            runtimeType == other.runtimeType &&
            keyword == other.keyword &&
            page == other.page &&
            pageSize == other.pageSize;
  }

  @override
  int get hashCode => Object.hash(keyword, page, pageSize);
}
