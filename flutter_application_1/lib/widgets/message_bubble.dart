import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  String _formatTime(DateTime timestamp) {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == MessageSender.user;
    final maxWidth = MediaQuery.of(context).size.width * 0.75;

    final bg = isUser
        ? theme.colorScheme.primary
        : theme.colorScheme.surfaceContainerHigh;
    final fg = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurfaceVariant;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: fg,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatTime(message.timestamp),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(left: 48, right: 12),
          child: bubble,
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(right: 48, left: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 18,
                color: theme.colorScheme.onPrimary,
              ),
            ),
            Flexible(child: bubble),
          ],
        ),
      ),
    );
  }
}
