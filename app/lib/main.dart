import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'screens/chat_screen.dart';
import 'theme/bank_theme.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.loggerName}: ${record.message}');
  });
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
