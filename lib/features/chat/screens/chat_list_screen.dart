import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/message.dart';
import 'package:logistics_app/core/services/chat_service.dart';
import 'package:logistics_app/features/chat/widgets/chat_room_card.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late Future<List<ChatRoom>> _futureRooms;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    setState(() {
      _futureRooms = ChatService.getRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Text(
                'Чат',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: primaryText,
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ChatRoom>>(
                future: _futureRooms,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Ошибка загрузки: ${snapshot.error}',
                            style: TextStyle(color: secondaryText)));
                  }

                  final rooms = snapshot.data ?? [];

                  if (rooms.isEmpty) {
                    return Center(
                        child: Text('Нет чатов',
                            style: TextStyle(color: secondaryText)));
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadRooms(),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => ChatRoomCard(room: rooms[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
