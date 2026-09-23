import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/message.dart';
import 'package:flutter_application_1/screens/chat_screen.dart';
import 'package:flutter_application_1/services/chat_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeChatService extends ChatService {
  FakeChatService() : super(baseUrl: 'http://localhost');

  @override
  Future<String> createConversation({required String userId}) async =>
      'fake-conv';

  @override
  Future<List<Message>> fetchHistory({
    required String userId,
    required String conversationId,
  }) async =>
      [];

  @override
  Future<Message> sendMessage({
    required String userId,
    required String conversationId,
    required String text,
    String? timezone,
  }) async {
    return Message(
      id: 'fake-reply',
      text: 'echo: $text',
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
    );
  }

  @override
  void dispose() {}
}

void main() {
  testWidgets('ChatScreen shows input and echoes sent message',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: ChatScreen(chatService: FakeChatService())),
    );
    await tester.pumpAndSettle();

    expect(find.text('MinChat'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('echo: Hello'), findsOneWidget);
  });
}
