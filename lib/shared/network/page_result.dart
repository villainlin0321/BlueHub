import 'api_decoders.dart';

class Pagination {
  const Pagination({
    required this.page,
    required this.total,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
  });

  final int page;
  final int total;
  final int pageSize;
  final int totalPages;
  final bool hasNext;

  factory Pagination.fromJson(JsonMap json) {
    return Pagination(
      page: (json['page'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toInt() ?? 0,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 0,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 0,
      hasNext: json['has_next'] as bool? ?? false,
    );
  }
}

class PageResult<T> {
  const PageResult({required this.list, required this.pagination});

  final List<T> list;
  final Pagination pagination;

  factory PageResult.fromJson(
    JsonMap json, {
    required T Function(JsonMap item) fromJson,
  }) {
    return PageResult<T>(
      list: decodeModelList<T>(json['list'] ?? const <dynamic>[], fromJson),
      pagination: Pagination.fromJson(
        asJsonMap(json['pagination'] ?? const <String, dynamic>{}),
      ),
    );
  }
}
