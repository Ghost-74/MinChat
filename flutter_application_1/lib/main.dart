import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';

void main() {
  runApp(const MinChatApp());
}

class MinChatApp extends StatelessWidget {
  const MinChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B5BD6),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF5B5BD6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MinChat',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        appBarTheme: AppBarTheme(
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkScheme,
      ),
      home: const ChatScreen(),
    );
  }
}
