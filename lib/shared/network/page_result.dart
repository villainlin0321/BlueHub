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
      page: readInt(json, 'page', fallback: 1),
      total: readInt(json, 'total'),
      pageSize: readInt(json, 'page_size'),
      totalPages: readInt(json, 'total_pages'),
      hasNext: readBool(json, 'has_next'),
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
      list: readModelList<T>(json, 'list', fromJson),
      pagination: Pagination.fromJson(
        readJsonMap(json, 'pagination'),
      ),
    );
  }
}
