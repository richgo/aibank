import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aibank_app/theme/bank_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Initialize Flutter test bindings for GoogleFonts
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // Configure GoogleFonts for testing to avoid HTTP requests
  GoogleFonts.config.allowRuntimeFetching = false;

  group('BankTheme Color Constants', () {
    test('primaryGreen should be #006B3D', () {
      expect(BankTheme.primaryGreen, const Color(0xFF006B3D));
    });

    test('accentCoral should be #FF6B6B', () {
      expect(BankTheme.accentCoral, const Color(0xFFFF6B6B));
    });

    test('textDark should be #1A1A1A', () {
      expect(BankTheme.textDark, const Color(0xFF1A1A1A));
    });

    test('backgroundLight should be #F5F5F5', () {
      expect(BankTheme.backgroundLight, const Color(0xFFF5F5F5));
    });

    test('surfaceWhite should be #FFFFFF', () {
      expect(BankTheme.surfaceWhite, const Color(0xFFFFFFFF));
    });

    test('positive should be #1B8A3A', () {
      expect(BankTheme.positive, const Color(0xFF1B8A3A));
    });

    test('negative should be #D32F2F', () {
      expect(BankTheme.negative, const Color(0xFFD32F2F));
    });
  });

  group('BankTheme Design Tokens', () {
    test('cardRadius should be 24.0', () {
      expect(BankTheme.cardRadius, 24.0);
    });

    test('panelRadius should be 16.0', () {
      expect(BankTheme.panelRadius, 16.0);
    });

    test('buttonRadius should be 8.0', () {
      expect(BankTheme.buttonRadius, 8.0);
    });

    test('elevationResting should be 2.0', () {
      expect(BankTheme.elevationResting, 2.0);
    });

    test('elevationInteractive should be 4.0', () {
      expect(BankTheme.elevationInteractive, 4.0);
    });

    test('elevationModal should be 8.0', () {
      expect(BankTheme.elevationModal, 8.0);
    });

    test('spacingCompact should be 12.0', () {
      expect(BankTheme.spacingCompact, 12.0);
    });

    test('spacing should be 16.0', () {
      expect(BankTheme.spacing, 16.0);
    });

    test('spacingSpacious should be 24.0', () {
      expect(BankTheme.spacingSpacious, 24.0);
    });
  });

  group('BankTheme Gradient Helpers', () {
    test('cardGradient should return LinearGradient with correct colors', () {
      final gradient = BankTheme.cardGradient();
      expect(gradient, isA<LinearGradient>());
      expect(gradient.colors, [const Color(0xFF006B3D), const Color(0xFF00A86B)]);
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
    });

    test('lightGradient should return LinearGradient with light green tints', () {
      final gradient = BankTheme.lightGradient();
      expect(gradient, isA<LinearGradient>());
      expect(gradient.colors, [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)]);
      expect(gradient.begin, Alignment.topLeft);
      expect(gradient.end, Alignment.bottomRight);
    });
  });

  group('BankTheme Light ThemeData', () {
    test('should have light brightness', () {
      final theme = BankTheme.light;
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('should have correct primary color', () {
      final theme = BankTheme.light;
      expect(theme.colorScheme.primary, BankTheme.primaryGreen);
    });

    test('should have correct secondary color', () {
      final theme = BankTheme.light;
      expect(theme.colorScheme.secondary, BankTheme.accentCoral);
    });

    test('should have correct error color', () {
      final theme = BankTheme.light;
      expect(theme.colorScheme.error, BankTheme.negative);
    });

    test('should have correct surface color', () {
      final theme = BankTheme.light;
      expect(theme.colorScheme.surface, BankTheme.surfaceWhite);
    });

    test('should have correct background color', () {
      final theme = BankTheme.light;
      expect(theme.scaffoldBackgroundColor, BankTheme.backgroundLight);
    });

    test('AppBarTheme should have primaryGreen background', () {
      final theme = BankTheme.light;
      expect(theme.appBarTheme.backgroundColor, BankTheme.primaryGreen);
    });

    test('AppBarTheme should have white foreground', () {
      final theme = BankTheme.light;
      expect(theme.appBarTheme.foregroundColor, BankTheme.surfaceWhite);
    });

    test('AppBarTheme should have zero elevation', () {
      final theme = BankTheme.light;
      expect(theme.appBarTheme.elevation, 0);
    });

    test('CardTheme should have correct elevation', () {
      final theme = BankTheme.light;
      expect(theme.cardTheme.elevation, BankTheme.elevationResting);
    });

    test('CardTheme should have white surface color', () {
      final theme = BankTheme.light;
      expect(theme.cardTheme.color, BankTheme.surfaceWhite);
    });

    test('CardTheme should have correct border radius', () {
      final theme = BankTheme.light;
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;
      expect(borderRadius.topLeft.x, BankTheme.panelRadius);
    });

    test('ElevatedButton should have primaryGreen background', () {
      final theme = BankTheme.light;
      expect(
        theme.elevatedButtonTheme.style?.backgroundColor?.resolve({}),
        BankTheme.primaryGreen,
      );
    });

    test('ElevatedButton should have white foreground', () {
      final theme = BankTheme.light;
      expect(
        theme.elevatedButtonTheme.style?.foregroundColor?.resolve({}),
        BankTheme.surfaceWhite,
      );
    });

    test('InputDecoration should have correct border radius', () {
      final theme = BankTheme.light;
      final border = theme.inputDecorationTheme.border! as OutlineInputBorder;
      final borderRadius = border.borderRadius;
      expect(borderRadius.topLeft.x, BankTheme.buttonRadius);
    });

    test('InputDecoration should have white fill color', () {
      final theme = BankTheme.light;
      expect(theme.inputDecorationTheme.fillColor, BankTheme.surfaceWhite);
    });

    test('InputDecoration should be filled', () {
      final theme = BankTheme.light;
      expect(theme.inputDecorationTheme.filled, true);
    });

    test('TextTheme should have correct text colors', () {
      final theme = BankTheme.light;
      expect(theme.textTheme.displayLarge?.color, BankTheme.textDark);
      expect(theme.textTheme.bodyLarge?.color, BankTheme.textDark);
    });
  });
}
