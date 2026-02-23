import 'package:aibank_app/catalog/banking_catalog.dart';
import 'package:aibank_app/catalog/mcp/mcp_app_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  group('Banking Catalogs', () {
    test('buildBankingCatalogs returns a single merged catalog', () {
      final catalogs = buildBankingCatalogs();
      expect(catalogs.length, 1);
    });

    test('catalog contains standard A2UI components', () {
      final catalog = buildBankingCatalogs()[0];
      expect(catalog.items.any((item) => item.name == 'Text'), isTrue);
      expect(catalog.items.any((item) => item.name == 'Column'), isTrue);
      expect(catalog.items.any((item) => item.name == 'Row'), isTrue);
    });

    test('catalog contains mcp:AppFrame', () {
      final catalog = buildBankingCatalogs()[0];
      expect(catalog.items.any((item) => item.name == 'mcp:AppFrame'), isTrue);
    });

    testWidgets('catalog resolves mcp:AppFrame key variants', (tester) async {
      final catalog = buildBankingCatalogs()[0];
      late BuildContext context;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              context = ctx;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      Widget buildFor(String widgetType) {
        return catalog.buildWidget(
          CatalogItemContext(
            data: {
              widgetType: {
                'mcpEndpointUrl': 'http://localhost:3001/mcp',
                'resourceUri': 'ui://cesium-map/mcp-app.html',
                'toolName': 'show-map',
                'toolInput': <String, Object?>{},
              },
            },
            id: 'map',
            buildChild: (_, [__]) => const SizedBox.shrink(),
            dispatchEvent: (_) {},
            buildContext: context,
            dataContext: DataContext(DataModel(), '/'),
            getComponent: (_) => null,
            surfaceId: 'main_surface',
          ),
        );
      }

      expect(buildFor('mcp:AppFrame'), isA<McpAppFrameWidget>());
      expect(buildFor('mcp:appframe'), isA<McpAppFrameWidget>());
      expect(buildFor(' mcp:AppFrame '), isA<McpAppFrameWidget>());
    });
  });
}
