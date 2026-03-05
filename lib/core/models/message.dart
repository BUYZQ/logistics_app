class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
  });
}

class ChatRoom {
  final String id;
  final String orderId;
  final String orderNumber;
  final String otherUserName;
  final String otherUserId;
  final List<ChatMessage> messages;
  final int unreadCount;

  const ChatRoom({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.otherUserName,
    required this.otherUserId,
    required this.messages,
    this.unreadCount = 0,
  });

  ChatMessage? get lastMessage =>
      messages.isEmpty ? null : messages.last;
}

class ChatStore {
  static final List<ChatRoom> _rooms = [
    ChatRoom(
      id: 'chat1',
      orderId: '2',
      orderNumber: 'ПИ-2024-002',
      otherUserName: 'Дмитрий Петров',
      otherUserId: 'ex1',
      unreadCount: 2,
      messages: [
        ChatMessage(
          id: 'm1',
          senderId: 'op1',
          senderName: 'Алексей Иванов',
          text: 'Дмитрий, заявка ПИ-2024-002 готова к выполнению',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          isRead: true,
        ),
        ChatMessage(
          id: 'm2',
          senderId: 'ex1',
          senderName: 'Дмитрий Петров',
          text: 'Принял, буду на месте через 20 минут',
          timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
          isRead: true,
        ),
        ChatMessage(
          id: 'm3',
          senderId: 'ex1',
          senderName: 'Дмитрий Петров',
          text: 'Уже загружаю товар',
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
      ],
    ),
    ChatRoom(
      id: 'chat2',
      orderId: '3',
      orderNumber: 'ПИ-2024-003',
      otherUserName: 'Дмитрий Петров',
      otherUserId: 'ex1',
      unreadCount: 0,
      messages: [
        ChatMessage(
          id: 'm4',
          senderId: 'op1',
          senderName: 'Алексей Иванов',
          text: 'Как дела с продуктами? Всё в порядке?',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          isRead: true,
        ),
        ChatMessage(
          id: 'm5',
          senderId: 'ex1',
          senderName: 'Дмитрий Петров',
          text: 'Да, груз принял, еду по маршруту',
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          isRead: true,
        ),
      ],
    ),
  ];

  static List<ChatRoom> getRoomsForUser(String userId) => List.from(_rooms);

  static ChatRoom? getRoomById(String id) {
    try {
      return _rooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  static void addMessage(String roomId, ChatMessage msg) {
    final idx = _rooms.indexWhere((r) => r.id == roomId);
    if (idx != -1) {
      final room = _rooms[idx];
      final updated = ChatRoom(
        id: room.id,
        orderId: room.orderId,
        orderNumber: room.orderNumber,
        otherUserName: room.otherUserName,
        otherUserId: room.otherUserId,
        messages: [...room.messages, msg],
        unreadCount: 0,
      );
      _rooms[idx] = updated;
    }
  }
}
