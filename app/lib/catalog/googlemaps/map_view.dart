import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:latlong2/latlong.dart';

import '../../theme/bank_theme.dart';

/// Creates a CatalogItem for the googlemaps:MapView component.
///
/// This component displays a map with a marker at the specified coordinates.
/// It's used to show transaction locations from geocoded merchant data.
CatalogItem mapViewItem() {
  final schema = S.object(
    properties: {
      'latitude': S.number(),
      'longitude': S.number(),
      'label': S.string(),
      'zoom': S.number(),
    },
    required: ['latitude', 'longitude'],
  );

  return CatalogItem(
    name: 'googlemaps:MapView',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final latitude = (map['latitude'] as num?)?.toDouble() ?? 0.0;
      final longitude = (map['longitude'] as num?)?.toDouble() ?? 0.0;
      final label = map['label'] as String? ?? '';
      final zoom = (map['zoom'] as num?)?.toDouble() ?? 15.0;

      return MapViewWidget(
        latitude: latitude,
        longitude: longitude,
        label: label,
        zoom: zoom,
      );
    },
  );
}

/// Widget that displays a map with a marker at the specified location.
///
/// Uses flutter_map with OpenStreetMap tiles for display.
/// For the POC, gestures are disabled (static display only).
class MapViewWidget extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String label;
  final double zoom;

  const MapViewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label = '',
    this.zoom = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);

    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BankTheme.cardRadius),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none, // Disable gestures for POC
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.aibank',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 40,
                  height: 40,
                  child: _buildMarker(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          color: BankTheme.primaryGreen,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
