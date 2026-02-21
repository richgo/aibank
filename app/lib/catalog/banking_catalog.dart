import 'package:genui/genui.dart';

import 'googlemaps/googlemaps_catalog.dart';

List<Catalog> buildBankingCatalogs() {
  return [CoreCatalogItems.asCatalog(), buildGoogleMapsCatalog()];
}
