import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  static final ChatSession _instance = ChatSession._internal();
  factory ChatSession() => _instance;
  ChatSession._internal();

  static const _uuid = Uuid();
  static const _prefsKey = 'minchat_session_id';

  String? _sessionId;
  DateTime? _createdAt;

  String? get currentId => _sessionId;

  String get sessionId {
    _sessionId ??= _uuid.v4();
    return _sessionId!;
  }

  Future<String> getOrCreate() async {
    if (_sessionId != null) return _sessionId!;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      _sessionId = saved;
    } else {
      _sessionId = _uuid.v4();
      await prefs.setString(_prefsKey, _sessionId!);
    }
    _createdAt ??= DateTime.now();
    return _sessionId!;
  }

  Future<String> reset() async {
    _sessionId = _uuid.v4();
    _createdAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, _sessionId!);
    return _sessionId!;
  }

  static String newMessageId() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  static String formatTimestamp(DateTime timestamp) =>
      timestamp.toUtc().toIso8601String();
}
