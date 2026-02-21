import 'package:genui/genui.dart';

import 'credit_card_summary.dart';
import 'googlemaps/googlemaps_catalog.dart';
import 'mortgage_detail.dart';
import 'savings_summary.dart';
import 'transaction_list.dart';

List<Catalog> buildBankingCatalogs() {
  final custom = Catalog([
    transactionListItem(),
    mortgageDetailItem(),
    creditCardSummaryItem(),
    savingsSummaryItem(),
  ]);
  return [CoreCatalogItems.asCatalog(), custom, buildGoogleMapsCatalog()];
}
