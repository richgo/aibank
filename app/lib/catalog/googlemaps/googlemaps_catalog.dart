import 'package:genui/genui.dart';

import 'map_view.dart';

/// Builds a catalog containing Google Maps MCP-App components.
///
/// Components in this catalog use the 'googlemaps:' namespace prefix
/// to avoid collisions with internal banking catalog items.
Catalog buildGoogleMapsCatalog() {
  return Catalog([
    mapViewItem(),
  ]);
}
