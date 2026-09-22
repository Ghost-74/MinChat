enum MessageSender {
  user,
  assistant,
}

class Message {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  const Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sender': sender.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromJson(Map<String, dynamic> json) {
    final senderStr = (json['sender'] ?? 'assistant').toString();
    return Message(
      id: (json['id'] ?? json['message_id'] ?? '').toString(),
      text: (json['text'] ?? json['reply'] ?? '').toString(),
      sender:
          senderStr == 'user' ? MessageSender.user : MessageSender.assistant,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}