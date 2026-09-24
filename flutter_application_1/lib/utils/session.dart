import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  static final ChatSession _instance = ChatSession._internal();
  factory ChatSession() => _instance;
  ChatSession._internal();

  static const _uuid = Uuid();
  static const _userKey = 'minchat_user_id';
  static const _convKey = 'minchat_conversation_id';
  static const _knownKey = 'minchat_known_conversations';

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

  Future<void> addKnownConversation(String id, {String title = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_knownKey);
      final Map<String, dynamic> map =
          raw != null && raw.isNotEmpty ? Map<String, dynamic>.from(
              (await _decode(raw))) : {};
      map[id] = {'title': title, 'updatedAt': DateTime.now().toIso8601String()};
      await prefs.setString(_knownKey, await _encode(map));
    } catch (_) {}
  }

  Future<Map<String, Map<String, String>>> getKnownConversations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_knownKey);
      if (raw == null || raw.isEmpty) return {};
      final map = Map<String, dynamic>.from(await _decode(raw));
      return map.map((k, v) {
        final m = v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
        return MapEntry(k, {
          'title': (m['title'] ?? '').toString(),
          'updatedAt': (m['updatedAt'] ?? '').toString(),
        });
      });
    } catch (_) {
      return {};
    }
  }

  static String newMessageId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  static String formatTimestamp(DateTime timestamp) =>
      timestamp.toUtc().toIso8601String();

  Future<Map<String, dynamic>> _decode(String raw) async =>
      Map<String, dynamic>.from(jsonDecode(raw) as Map);

  Future<String> _encode(Map<String, dynamic> map) async =>
      jsonEncode(map);
}
