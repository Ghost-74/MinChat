import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  static final ChatSession _instance = ChatSession._internal();
  factory ChatSession() => _instance;
  ChatSession._internal();

  static const _uuid = Uuid();
  static const _userKey = 'minchat_user_id';
  static const _convKey = 'minchat_conversation_id';

  String? _userId;
  String? _conversationId;

  String? get currentId => _userId;
  String? get currentConversationId => _conversationId;

  String get sessionId {
    _userId ??= _uuid.v4();
    return _userId!;
  }

  Future<String> getOrCreate() => getOrCreateUserId();

  Future<String> getOrCreateUserId() async {
    if (_userId != null) return _userId!;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_userKey);
    if (saved != null && saved.isNotEmpty) {
      _userId = saved;
    } else {
      _userId = _uuid.v4();
      await prefs.setString(_userKey, _userId!);
    }
    return _userId!;
  }

  Future<String?> getConversationId() async {
    if (_conversationId != null) return _conversationId;
    final prefs = await SharedPreferences.getInstance();
    _conversationId = prefs.getString(_convKey);
    return _conversationId;
  }

  Future<void> setConversationId(String id) async {
    _conversationId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_convKey, id);
  }

  Future<String> reset() async {
    _conversationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_convKey);
    return getOrCreateUserId();
  }

  Future<void> clearConversation() async {
    _conversationId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_convKey);
  }

  static String newMessageId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  static String formatTimestamp(DateTime timestamp) =>
      timestamp.toUtc().toIso8601String();
}
