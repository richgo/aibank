import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aibank_app/widgets/brand_logo.dart';

void main() {
  group('BrandLogo Widget', () {
    testWidgets('renders without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandLogo(),
          ),
        ),
      );

      expect(find.byType(BrandLogo), findsOneWidget);
    });

    testWidgets('renders with default size of 40', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandLogo(),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(BrandLogo),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 40);
      expect(sizedBox.height, 40);
    });

    testWidgets('renders with custom size', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandLogo(size: 80),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find.descendant(
          of: find.byType(BrandLogo),
          matching: find.byType(SizedBox),
        ),
      );

      expect(sizedBox.width, 80);
      expect(sizedBox.height, 80);
    });

    testWidgets('contains CustomPaint with SwiftFoxPainter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrandLogo(),
          ),
        ),
      );

      final customPaint = find.descendant(
        of: find.byType(BrandLogo),
        matching: find.byType(CustomPaint),
      );
      expect(customPaint, findsOneWidget);
    });
  });
}
