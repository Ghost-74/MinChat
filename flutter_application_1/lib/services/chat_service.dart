import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/message.dart';
import '../utils/session.dart';

class ChatException implements Exception {
  final String message;
  ChatException(this.message);

  @override
  String toString() => 'ChatException: $message';
}

class ChatService {
  final String baseUrl;
  final http.Client _client;

  ChatService({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<Message> sendMessage({
    required String text,
    required String sessionId,
  }) async {
    final uri = Uri.parse('$baseUrl/chat');

    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_id': sessionId,
              'message_id': ChatSession.newMessageId(),
              'text': text,
              'timestamp': ChatSession.formatTimestamp(DateTime.now()),
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      throw ChatException('Could not reach backend: $e');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ChatException(
        'Backend error ${response.statusCode}: ${response.body}',
      );
    }

    try {
      final data = jsonDecode(response.body);
      final Map<String, dynamic> json =
          data is Map<String, dynamic> ? data : {'reply': data.toString()};

      final replyText = (json['reply'] ??
              json['text'] ??
              json['response'] ??
              json['message'] ??
              '')
          .toString();

      if (replyText.isEmpty) {
        throw ChatException('Empty reply from backend: ${response.body}');
      }

      return Message(
        id: (json['message_id']?.toString()) ?? ChatSession.newMessageId(),
        text: replyText,
        sender: MessageSender.assistant,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (e is ChatException) rethrow;
      throw ChatException('Bad backend response: $e');
    }
  }

  void dispose() => _client.close();

  Future<List<Message>> fetchHistory(String sessionId) async {
    try {
      final uri = Uri.parse('$baseUrl/history?session_id=$sessionId');
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) return [];
      final data = jsonDecode(response.body);
      final List<dynamic> raw;
      if (data is List) {
        raw = data;
      } else if (data is Map<String, dynamic>) {
        final m = data['messages'] ?? data['history'] ?? data['data'] ?? [];
        raw = m is List ? m : [];
      } else {
        return [];
      }
      return raw.whereType<Map<String, dynamic>>().map((m) {
        final senderStr = (m['sender'] ?? m['role'] ?? 'assistant').toString();
        return Message(
          id: (m['message_id'] ?? m['id'] ?? ChatSession.newMessageId())
              .toString(),
          text: (m['text'] ?? m['reply'] ?? m['response'] ?? m['message'] ?? '')
              .toString(),
          sender: senderStr == 'user'
              ? MessageSender.user
              : MessageSender.assistant,
          timestamp: DateTime.tryParse(m['timestamp']?.toString() ?? '') ??
              DateTime.now(),
        );
      }).where((m) => m.text.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}
