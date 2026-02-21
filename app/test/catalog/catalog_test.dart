import 'package:flutter_test/flutter_test.dart';
import 'package:aibank_app/catalog/banking_catalog.dart';
import 'package:genui/genui.dart';

void main() {
  group('Banking Catalogs', () {
    test('buildBankingCatalogs returns core and google maps catalogs', () {
      final catalogs = buildBankingCatalogs();
      expect(catalogs.length, 2);
    });

    test('core catalog contains standard A2UI components', () {
      final catalogs = buildBankingCatalogs();
      final core = catalogs[0];
      // Core catalog has standard components like Text, Column, Row, List, Button
      expect(core.items.any((item) => item.name == 'Text'), isTrue);
      expect(core.items.any((item) => item.name == 'Column'), isTrue);
      expect(core.items.any((item) => item.name == 'Row'), isTrue);
    });
  });
}
