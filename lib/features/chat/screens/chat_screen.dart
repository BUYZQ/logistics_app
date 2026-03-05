import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logistics_app/app/theme.dart';
import 'package:logistics_app/core/models/message.dart';
import 'package:logistics_app/core/models/user.dart';
import 'package:logistics_app/features/chat/widgets/message_bubble.dart';
import 'package:logistics_app/features/chat/widgets/date_divider.dart';
import 'package:logistics_app/features/chat/widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  ChatRoom? _room;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _room = ChatStore.getRoomById(widget.roomId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();
    setState(() => _sending = true);
    final msg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: AuthState.currentUser!.id,
      senderName: AuthState.currentUser!.name,
      text: text,
      timestamp: DateTime.now(),
      isRead: true,
    );
    ChatStore.addMessage(widget.roomId, msg);
    _room = ChatStore.getRoomById(widget.roomId);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.background : AppTheme.lBackground;
    final primaryText = isDark ? AppTheme.textPrimary : AppTheme.lTextPrimary;
    final secondaryText = isDark ? AppTheme.textSecondary : AppTheme.lTextSecondary;
    final successColor = isDark ? AppTheme.success : AppTheme.lSuccess;

    if (_room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final msgs = _room!.messages;
    final myId = AuthState.currentUser!.id;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primaryText, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_room!.otherUserName,
                style: TextStyle(fontSize: 16, color: primaryText)),
            Text(_room!.orderNumber,
                style: TextStyle(fontSize: 11, color: secondaryText)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                  color: successColor, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final msg = msgs[i];
                final isMe = msg.senderId == myId;
                final showDate = i == 0 ||
                    !_isSameDay(msgs[i - 1].timestamp, msg.timestamp);
                return Column(
                  children: [
                    if (showDate) DateDivider(date: msg.timestamp),
                    MessageBubble(msg: msg, isMe: isMe),
                  ],
                );
              },
            ),
          ),
          ChatInputBar(
              ctrl: _textCtrl, onSend: _send, sending: _sending),
        ],
      ),
    );
  }
}
