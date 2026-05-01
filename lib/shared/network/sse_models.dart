class SseEvent {
  const SseEvent({this.id, this.event, required this.data, this.retry});

  final String? id;
  final String? event;
  final String data;
  final int? retry;

  bool get hasData => data.trim().isNotEmpty;
}
