class ChatPageArgs {
  const ChatPageArgs({
    required this.targetUserId,
    required this.targetUserRole,
    required this.nickname,
    required this.avatarUrl,
    this.conversationId = 0,
    this.isOnline = false,
    this.relatedOrderId = 0,
    this.packageName = '',
    this.orderStatus = '',
  });

  final int targetUserId;
  final String targetUserRole;
  final String nickname;
  final String avatarUrl;
  final int conversationId;
  final bool isOnline;
  final int relatedOrderId;
  final String packageName;
  final String orderStatus;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ChatPageArgs &&
        other.targetUserId == targetUserId &&
        other.targetUserRole == targetUserRole &&
        other.nickname == nickname &&
        other.avatarUrl == avatarUrl &&
        other.conversationId == conversationId &&
        other.isOnline == isOnline &&
        other.relatedOrderId == relatedOrderId &&
        other.packageName == packageName &&
        other.orderStatus == orderStatus;
  }

  @override
  int get hashCode => Object.hash(
    targetUserId,
    targetUserRole,
    nickname,
    avatarUrl,
    conversationId,
    isOnline,
    relatedOrderId,
    packageName,
    orderStatus,
  );
}
