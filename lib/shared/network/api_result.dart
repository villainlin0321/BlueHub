class ApiResult<T> {
  const ApiResult({
    required this.code,
    required this.message,
    required this.data,
    required this.timestamp,
    required this.requestId,
  });

  final int code;
  final String message;
  final T? data;
  final int? timestamp;
  final String? requestId;

  bool get isSuccess => code == 0;

  static ApiResult<T> fromJson<T>(
    Map<String, dynamic> json, {
    required T Function(dynamic data) decode,
  }) {
    final code = (json['code'] as num?)?.toInt() ?? -1;
    final message = (json['message'] as String?) ?? '';
    final dataRaw = json['data'];
    final data = dataRaw == null ? null : decode(dataRaw);
    final timestamp = (json['timestamp'] as num?)?.toInt();
    final requestId = json['requestId'] as String?;

    return ApiResult<T>(
      code: code,
      message: message,
      data: data,
      timestamp: timestamp,
      requestId: requestId,
    );
  }
}
