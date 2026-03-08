class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'].toString(),
      senderId: json['sender_id'].toString(),
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String).toLocal(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }
}

class ChatRoom {
  final String id;
  final String orderId;
  final String orderNumber;
  final String otherUserName;
  final String otherUserId;
  final String? otherUserAvatarUrl;
  final List<ChatMessage> messages;
  final int unreadCount;
  final ChatMessage? lastMessage;

  const ChatRoom({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.otherUserName,
    required this.otherUserId,
    this.otherUserAvatarUrl,
    this.messages = const [],
    this.unreadCount = 0,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    ChatMessage? last;
    if (json['last_message'] != null) {
      last = ChatMessage.fromJson(json['last_message']);
    }
    
    List<ChatMessage> msgs = [];
    if (json['messages'] != null) {
      msgs = (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ChatRoom(
      id: json['id'].toString(),
      orderId: json['order_id'] ?? '',
      orderNumber: json['order_number'] ?? '',
      otherUserName: json['other_user_name'] ?? 'Неизвестно',
      otherUserId: json['other_user_id']?.toString() ?? '',
      otherUserAvatarUrl: json['other_user_avatar_url'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      lastMessage: last,
      messages: msgs,
    );
  }
}
