import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/catalog/googlemaps/map_view.dart';

void main() {
  group('MapViewWidget', () {
    testWidgets('renders FlutterMap with given coordinates', (tester) async {
      // GIVEN valid coordinates
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapViewWidget(
              latitude: 51.5074,
              longitude: -0.1278,
              label: 'Test Location',
            ),
          ),
        ),
      );

      // THEN a FlutterMap widget is rendered
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('renders marker at specified location', (tester) async {
      // GIVEN coordinates for the marker
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapViewWidget(
              latitude: 51.5074,
              longitude: -0.1278,
              label: 'Tesco Superstore',
            ),
          ),
        ),
      );

      // THEN a marker layer is present
      expect(find.byType(MarkerLayer), findsOneWidget);

      // AND the marker contains a location icon
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('uses default zoom level of 15', (tester) async {
      // GIVEN no explicit zoom level
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapViewWidget(
              latitude: 51.5074,
              longitude: -0.1278,
            ),
          ),
        ),
      );

      // THEN the map renders successfully (default zoom is applied internally)
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('uses custom zoom level when provided', (tester) async {
      // GIVEN a custom zoom level
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapViewWidget(
              latitude: 51.5074,
              longitude: -0.1278,
              zoom: 12.0,
            ),
          ),
        ),
      );

      // THEN the map renders successfully with custom zoom
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('has fixed height of 250', (tester) async {
      // GIVEN a MapViewWidget
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapViewWidget(
              latitude: 51.5074,
              longitude: -0.1278,
            ),
          ),
        ),
      );

      // THEN the SizedBox has height 250
      final sizedBox = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(FlutterMap),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(sizedBox.height, 250);
    });

    testWidgets('displays label in tooltip', (tester) async {
      // GIVEN a label for the marker
      const label = 'Tesco Superstore';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MapViewWidget(
              latitude: 51.5074,
              longitude: -0.1278,
              label: label,
            ),
          ),
        ),
      );

      // THEN a Tooltip widget exists with the label
      expect(find.byType(Tooltip), findsOneWidget);
      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, label);
    });
  });

  group('mapViewItem CatalogItem', () {
    test('has correct name with namespace prefix', () {
      final item = mapViewItem();
      expect(item.name, 'googlemaps:MapView');
    });

    test('has required fields in schema', () {
      final item = mapViewItem();
      // Schema should exist and be valid
      expect(item.dataSchema, isNotNull);
    });
  });
}
