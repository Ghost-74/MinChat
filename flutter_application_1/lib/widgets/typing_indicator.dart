import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(ThemeData theme, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = ((_controller.value - delay) % 1.0) / 0.6;
        final clamped = t.clamp(0.0, 1.0);
        final scale = clamped < 0.5
            ? 0.6 + (clamped * 0.8)
            : 1.0 - ((clamped - 0.5) * 0.8);
        final opacity = 0.4 + (scale - 0.6);
        return Opacity(
          opacity: opacity.clamp(0.4, 1.0),
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dot(theme, 0.0),
                  const SizedBox(width: 5),
                  _dot(theme, 0.2),
                  const SizedBox(width: 5),
                  _dot(theme, 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
