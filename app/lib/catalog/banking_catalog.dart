import 'package:genui/genui.dart';

import 'account_card.dart';
import 'account_detail.dart';
import 'account_overview.dart';
import 'credit_card_summary.dart';
import 'googlemaps/googlemaps_catalog.dart';
import 'mortgage_detail.dart';
import 'savings_summary.dart';
import 'transaction_list.dart';

List<Catalog> buildBankingCatalogs() {
  final custom = Catalog([
    accountCardItem(),
    accountDetailViewItem(),
    transactionListItem(),
    mortgageDetailItem(),
    creditCardSummaryItem(),
    savingsSummaryItem(),
    accountOverviewItem(),
  ]);
  return [CoreCatalogItems.asCatalog(), custom, buildGoogleMapsCatalog()];
}
