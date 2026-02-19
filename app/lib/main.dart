import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'screens/chat_screen.dart';
import 'theme/bank_theme.dart';

void main() {
  Logger.root.level = Level.INFO;
  runApp(const AIBankApp());
}

class AIBankApp extends StatelessWidget {
  const AIBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIBank',
      theme: BankTheme.light,
      home: const ChatScreen(),
    );
  }
}
