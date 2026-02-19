import 'package:aibank_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('chat screen renders input and send button', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatScreen(enableAgent: false)));

    expect(find.text('AIBank'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.send), findsOneWidget);
  });

  testWidgets('sending text immediately shows user message', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChatScreen(enableAgent: false)));

    await tester.enterText(find.byType(TextField), 'show my accounts');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    expect(find.text('show my accounts'), findsOneWidget);
  });
}
