import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../services/chat_service.dart';
import '../utils/session.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends StatefulWidget {
  final ChatService? chatService;

  const ChatScreen({super.key, this.chatService});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final ChatService _chatService =
      widget.chatService ?? ChatService(baseUrl: 'http://172.31.99.216:8000');
  String? userId;
  String? conversationId;
  bool isLoadingHistory = true;

  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _initSession();
  }

  Future<void> _initSession() async {
    final uid = await ChatSession().getOrCreateUserId();
    if (!mounted) return;
    setState(() => userId = uid);

    var cid = await ChatSession().getConversationId();
    if (cid == null) {
      try {
        cid = await _chatService.createConversation(userId: uid);
        await ChatSession().setConversationId(cid);
      } catch (_) {
        cid = ChatSession.newMessageId();
        await ChatSession().setConversationId(cid);
      }
    }
    if (!mounted) return;
    setState(() => conversationId = cid);

    final local = await _loadLocal(cid);
    if (!mounted) return;
    setState(() {
      messages.addAll(local);
      isLoadingHistory = false;
    });
    _scrollToBottom();

    final history = await _chatService.fetchHistory(
      userId: uid,
      conversationId: cid,
    );
    if (!mounted || history.isEmpty) return;
    setState(() {
      messages
        ..clear()
        ..addAll(history);
    });
    await _persistLocal();
    _scrollToBottom();
  }

  String _cacheKey(String id) => 'minchat_messages_$id';

  Future<List<Message>> _loadLocal(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey(id));
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Message.fromJson)
          .where((m) => m.text.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistLocal() async {
    try {
      final id = conversationId;
      if (id == null) return;
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString(_cacheKey(id), raw);
    } catch (_) {}
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || isTyping || userId == null || conversationId == null) {
      return;
    }

    messageController.clear();

    setState(() {
      messages.add(
        Message(
          id: ChatSession.newMessageId(),
          text: text,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      isTyping = true;
    });
    _persistLocal();
    _scrollToBottom();

    try {
      final reply = await _chatService.sendMessage(
        userId: userId!,
        conversationId: conversationId!,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        messages.add(reply);
        isTyping = false;
      });
      _persistLocal();
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add(
          Message(
            id: ChatSession.newMessageId(),
            text: 'Failed to get reply: ${e.message}',
            sender: MessageSender.assistant,
            timestamp: DateTime.now(),
          ),
        );
        isTyping = false;
      });
      _persistLocal();
    }
    _scrollToBottom();
  }

  Future<void> newChat() async {
    final uid = userId ?? await ChatSession().getOrCreateUserId();
    String? cid;
    try {
      cid = await _chatService.createConversation(userId: uid);
    } catch (_) {
      cid = ChatSession.newMessageId();
    }
    await ChatSession().setConversationId(cid);
    if (!mounted) return;
    setState(() {
      messages.clear();
      isTyping = false;
      isLoadingHistory = false;
      userId = uid;
      conversationId = cid;
    });
    messageController.clear();
    _persistLocal();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemCount = messages.length + (isTyping ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.smart_toy_outlined,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ),
        title: const Text('MinChat'),
        actions: [
          IconButton(
            tooltip: 'New chat',
            onPressed: newChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty && !isTyping
                    ? _EmptyState(theme: theme)
                    : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: itemCount,
                    itemBuilder: (context, index) {
                      if (isTyping && index == messages.length) {
                        return const TypingIndicator();
                      }
                      return MessageBubble(
                        message: messages[index],
                      );
                    },
                  ),
          ),
          MessageInput(
            controller: messageController,
            onSend: sendMessage,
            isSending: isTyping,
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  const _EmptyState({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.forum_outlined,
                size: 40,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Say hello to MinChat',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ask anything and get an instant reply.\nYour conversation stays in this session.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
