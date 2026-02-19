import 'package:aibank_app/catalog/account_card.dart';
import 'package:aibank_app/catalog/account_overview.dart';
import 'package:aibank_app/catalog/credit_card_summary.dart';
import 'package:aibank_app/catalog/mortgage_detail.dart';
import 'package:aibank_app/catalog/savings_summary.dart';
import 'package:aibank_app/catalog/transaction_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('banking catalog items expose expected names', () {
    expect(accountCardItem().name, 'AccountCard');
    expect(transactionListItem().name, 'TransactionList');
    expect(mortgageDetailItem().name, 'MortgageDetail');
    expect(creditCardSummaryItem().name, 'CreditCardSummary');
    expect(savingsSummaryItem().name, 'SavingsSummary');
    expect(accountOverviewItem().name, 'AccountOverview');
  });
}
