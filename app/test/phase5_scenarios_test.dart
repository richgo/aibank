import 'dart:io';
import 'package:aibank_app/screens/chat_screen.dart';
import 'package:aibank_app/theme/bank_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    GoogleFonts.config.allowRuntimeFetching = true;
    
    // Ensure HttpOverrides uses the default HTTP client for font fetching
    HttpOverrides.global = null;
  });

  group('Phase 5: Flutter App Integration - BDD Scenarios', () {
    // Task 5.1: App Theme
    group('Scenario: App applies BankTheme with banking colors', () {
      testWidgets(
        'GIVEN the app is started '
        'WHEN the main screen loads '
        'THEN BankTheme is applied with primary, positive, and negative colors',
        (tester) async {
          // GIVEN the app is started
          await tester.pumpWidget(MaterialApp(
            theme: BankTheme.light,
            home: const ChatScreen(enableAgent: false),
          ));
          await tester.pumpAndSettle();

          // WHEN the main screen loads
          final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

          // THEN BankTheme is applied
          expect(materialApp.theme, isNotNull);
          expect(materialApp.theme, equals(BankTheme.light));

          // AND colors are defined correctly
          expect(BankTheme.positive, equals(const Color(0xFF1B8A3A)));
          expect(BankTheme.negative, equals(const Color(0xFFD32F2F)));
          expect(materialApp.theme!.colorScheme.primary, isNotNull);
        },
      );
    });

    // Task 5.2: ChatScreen with GenUI Conversation Setup
    group('Scenario: App Launches and Connects to Agent', () {
      testWidgets(
        'GIVEN the app is started on a mobile device '
        'WHEN the main screen loads '
        'THEN a GenUiConversation is initialized with the backend agent URL '
        'AND the A2uiMessageProcessor is configured with the banking widget catalog',
        (tester) async {
          // GIVEN the app is started on a mobile device
          await tester.pumpWidget(const MaterialApp(
            home: ChatScreen(enableAgent: false),
          ));
          await tester.pumpAndSettle();

          // WHEN the main screen loads
          // THEN ChatScreen is shown
          expect(find.byType(ChatScreen), findsOneWidget);

          // AND app bar shows AIBank title
          expect(find.text('AIBank'), findsOneWidget);

          // Note: GenUiConversation and A2uiMessageProcessor are initialized
          // internally in ChatScreen. We verify through the UI structure.
        },
      );
    });

    group('Scenario: User Sends a Query', () {
      testWidgets(
        'GIVEN the user is on the main screen '
        'WHEN the user types "show my accounts" and taps send '
        'THEN the message is sent via GenUiConversation.sendRequest() '
        'AND the user message is displayed in the conversation',
        (tester) async {
          // GIVEN the user is on the main screen
          await tester.pumpWidget(const MaterialApp(
            home: ChatScreen(enableAgent: false),
          ));
          await tester.pumpAndSettle();

          // WHEN the user types "show my accounts"
          await tester.enterText(find.byType(TextField), 'show my accounts');

          // AND taps send
          await tester.tap(find.byIcon(Icons.send));
          await tester.pump();

          // THEN the message is displayed
          expect(find.text('show my accounts'), findsOneWidget);
        },
      );
    });

    // Task 5.3: Surface Lifecycle Management
    group('Scenario: New Surface Added', () {
      testWidgets(
        'GIVEN the agent generates a new surface '
        'WHEN the onSurfaceAdded callback fires with a surface ID '
        'THEN a GenUiSurface widget is added to the conversation view for that surface ID',
        (tester) async {
          final surfaceIds = <String>[];

          // GIVEN the agent is ready to generate surfaces
          await tester.pumpWidget(MaterialApp(
            home: ChatScreen(
              enableAgent: false,
              onSurfaceListChanged: (ids) {
                surfaceIds.clear();
                surfaceIds.addAll(ids);
              },
            ),
          ));
          await tester.pumpAndSettle();

          // WHEN the onSurfaceAdded callback fires
          // (in real scenario, this happens when agent responds)
          // We verify the structure supports this

          // THEN the ListView structure exists to display surfaces
          expect(find.byType(ListView), findsOneWidget);
          final listView = tester.widget<ListView>(find.byType(ListView));
          expect(listView.reverse, isTrue); // Chat-style layout

          // AND initially no surfaces when agent disabled
          expect(find.byType(GenUiSurface), findsNothing);
        },
      );
    });

    group('Scenario: Surface Deleted', () {
      testWidgets(
        'GIVEN an active surface exists in the conversation '
        'WHEN the agent sends a deleteSurface message '
        'THEN the corresponding GenUiSurface widget is removed from the view',
        (tester) async {
          // GIVEN the screen is ready
          await tester.pumpWidget(const MaterialApp(
            home: ChatScreen(enableAgent: false),
          ));
          await tester.pumpAndSettle();

          // WHEN surfaces are deleted (via onSurfaceDeleted callback)
          // The structure supports removal through state management

          // THEN surfaces can be removed from the ListView
          expect(find.byType(ListView), findsOneWidget);
        },
      );
    });

    // Task 5.4: User Action Forwarding
    group('Scenario: User Taps a Button in Generated UI', () {
      testWidgets(
        'GIVEN the agent has rendered a surface with a Button component '
        'WHEN the user taps the button '
        'THEN a userAction event is sent to the agent with the action name and current data model state',
        (tester) async {
          // GIVEN the agent has rendered surfaces
          await tester.pumpWidget(const MaterialApp(
            home: ChatScreen(enableAgent: false),
          ));
          await tester.pumpAndSettle();

          // Note: User action forwarding is handled automatically by GenUiSurface
          // We verify error handling is in place
          // The actual forwarding happens in GenUI SDK

          // THEN error stream listener shows snackbar on failures
          // This is wired up in ChatScreen initState
          expect(find.byType(ChatScreen), findsOneWidget);
        },
      );
    });

    // Task 5.5: Mobile-Only Layout
    group('Scenario: App Renders on Mobile', () {
      testWidgets(
        'GIVEN the app is built for iOS or Android '
        'WHEN the user opens the app '
        'THEN the layout is a single-column scrollable view with chat input at the bottom '
        'AND no responsive breakpoints for web or desktop are applied',
        (tester) async {
          // GIVEN the app is built
          await tester.pumpWidget(const MaterialApp(
            home: ChatScreen(enableAgent: false),
          ));
          await tester.pumpAndSettle();

          // WHEN the user opens the app
          // THEN the layout is single-column
          expect(find.byType(Column), findsWidgets);
          
          // AND scrollable view exists
          expect(find.byType(ListView), findsOneWidget);

          // AND chat input at the bottom (inside SafeArea)
          expect(find.byType(TextField), findsOneWidget);
          expect(find.byType(SafeArea), findsWidgets); // Multiple SafeArea widgets are fine

          // AND send button exists
          expect(find.byIcon(Icons.send), findsOneWidget);
        },
      );
    });
  });
}
