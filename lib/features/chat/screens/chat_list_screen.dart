import 'package:flutter/material.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/message.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/features/chat/widgets/chat_room_card.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rooms = ChatStore.getRoomsForUser(AuthState.currentUser?.id ?? '');

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
              child: rooms.isEmpty
                  ? Center(
                      child: Text('Нет чатов',
                          style: TextStyle(color: secondaryText)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => ChatRoomCard(room: rooms[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
