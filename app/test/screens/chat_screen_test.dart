import 'package:aibank_app/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

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

  group('Surface Lifecycle Management', () {
    testWidgets('initially has no surfaces when agent disabled', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ChatScreen(enableAgent: false)));

      // Should not have any GenUiSurface widgets when agent is disabled
      expect(find.byType(GenUiSurface), findsNothing);
    });

    testWidgets('chat screen structure supports surface rendering', (tester) async {
      // This test verifies the widget tree structure is correct for surface lifecycle
      await tester.pumpWidget(const MaterialApp(home: ChatScreen(enableAgent: false)));

      // Verify the basic structure exists: AppBar, ListView, TextField
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('surfaces would appear in the scrollable list', (tester) async {
      // Test that the widget structure allows surfaces to be displayed
      await tester.pumpWidget(const MaterialApp(home: ChatScreen(enableAgent: false)));

      // The scroll view should be expandable to show dynamic content
      final expanded = find.ancestor(
        of: find.byType(ListView),
        matching: find.byType(Expanded),
      );
      expect(expanded, findsOneWidget);
    });
  });
}
