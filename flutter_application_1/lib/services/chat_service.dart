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

  String _tz() {
    try {
      final name = DateTime.now().timeZoneName;
      if (name.contains('/')) return name;
    } catch (_) {}
    return 'Asia/Kolkata';
  }

  Future<String> createConversation({required String userId}) async {
    final uri = Uri.parse('$baseUrl/api/conversations');
    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 15));
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
      final id = (data is Map<String, dynamic> ? data['id'] : null)?.toString();
      if (id == null || id.isEmpty) {
        throw ChatException('Bad conversation response: ${response.body}');
      }
      return id;
    } catch (e) {
      if (e is ChatException) rethrow;
      throw ChatException('Bad backend response: $e');
    }
  }

  Future<Message> sendMessage({
    required String userId,
    required String conversationId,
    required String text,
    String? timezone,
  }) async {
    final uri = Uri.parse('$baseUrl/api/messages');
    late http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'conversationId': conversationId,
              'message': text,
              'timezone': timezone ?? _tz(),
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
      String replyText = '';
      String replyId = '';
      if (data is Map<String, dynamic>) {
        final a = data['assistantMessage'];
        if (a is Map<String, dynamic>) {
          replyText = (a['content'] ?? '').toString();
          replyId = (a['id'] ?? '').toString();
        } else {
          replyText = (data['reply'] ??
                  data['text'] ??
                  data['response'] ??
                  data['message'] ??
                  '')
              .toString();
          replyId = (data['message_id'] ?? data['id'] ?? '').toString();
        }
      }
      if (replyText.isEmpty) {
        throw ChatException('Empty reply from backend: ${response.body}');
      }
      return Message(
        id: replyId.isNotEmpty ? replyId : ChatSession.newMessageId(),
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

  Future<List<Message>> fetchHistory({
    required String userId,
    required String conversationId,
  }) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/api/conversations/$conversationId/messages?userId=$userId');
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));
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
        final role = (m['role'] ?? m['sender'] ?? 'assistant').toString();
        return Message(
          id: (m['id'] ?? m['message_id'] ?? ChatSession.newMessageId())
              .toString(),
          text: (m['content'] ??
                  m['text'] ??
                  m['reply'] ??
                  m['response'] ??
                  m['message'] ??
                  '')
              .toString(),
          sender:
              role == 'user' ? MessageSender.user : MessageSender.assistant,
          timestamp:
              DateTime.tryParse(m['createdAt']?.toString() ?? '') ??
                  DateTime.tryParse(m['timestamp']?.toString() ?? '') ??
                  DateTime.now(),
        );
      }).where((m) => m.text.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }
}
