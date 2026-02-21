import 'package:aibank_app/catalog/credit_card_summary.dart';
import 'package:aibank_app/catalog/mortgage_detail.dart';
import 'package:aibank_app/catalog/savings_summary.dart';
import 'package:aibank_app/catalog/transaction_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

CatalogItemContext _createContext(BuildContext buildContext, Map<String, Object?> data) {
  return CatalogItemContext(
    data: data,
    id: 'test-id',
    buildChild: (id, [dataContext]) => const SizedBox(),
    dispatchEvent: (event) {},
    buildContext: buildContext,
    dataContext: DataContext(_MockDataModel(data), ''),
    getComponent: (id) => null,
    surfaceId: 'test-surface',
  );
}

void main() {
  group('Catalog Item Names', () {
    test('banking catalog items expose expected names', () {
      expect(transactionListItem().name, 'TransactionList');
      expect(mortgageDetailItem().name, 'MortgageDetail');
      expect(creditCardSummaryItem().name, 'CreditCardSummary');
      expect(savingsSummaryItem().name, 'SavingsSummary');
    });
  });

  group('TransactionList Component', () {
    testWidgets('renders transaction rows with date, description, and amount', (tester) async {
      final catalogItem = transactionListItem();
      final mockData = {
        'items': [
          {
            'date': '2024-01-15',
            'description': 'Coffee Shop',
            'amount': '3.50',
            'type': 'debit',
          },
          {
            'date': '2024-01-14',
            'description': 'Salary',
            'amount': '2500.00',
            'type': 'credit',
          },
        ],
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('15 Jan'), findsOneWidget);
      expect(find.text('-£3.50'), findsOneWidget);
      
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('14 Jan'), findsOneWidget);
      expect(find.text('+£2500.00'), findsOneWidget);
    });

    testWidgets('displays empty state message when no transactions', (tester) async {
      final catalogItem = transactionListItem();
      final mockData = {'items': []};

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('No transactions found'), findsOneWidget);
    });
  });

  group('MortgageDetail Component', () {
    testWidgets('renders mortgage information with property address and balances', (tester) async {
      final catalogItem = mortgageDetailItem();
      final mockData = {
        'payload': {
          'propertyAddress': '123 Main St, London',
          'outstandingBalance': '250000.00',
          'monthlyPayment': '1200.00',
          'interestRate': '3.5',
          'rateType': 'Fixed',
        },
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('123 Main St, London'), findsOneWidget);
      expect(find.text('Outstanding Balance'), findsOneWidget);
      expect(find.text('£250000.00'), findsOneWidget);
      expect(find.text('Monthly Payment'), findsOneWidget);
      expect(find.text('£1200.00'), findsOneWidget);
      expect(find.text('Interest Rate'), findsOneWidget);
      expect(find.text('3.5% (Fixed)'), findsOneWidget);
    });
  });

  group('CreditCardSummary Component', () {
    testWidgets('renders credit card info with utilization bar', (tester) async {
      final catalogItem = creditCardSummaryItem();
      final mockData = {
        'payload': {
          'cardNumber': '**** **** **** 1234',
          'creditLimit': '5000',
          'currentBalance': '2500',
          'availableCredit': '2500',
        },
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('**** **** **** 1234'), findsOneWidget);
      expect(find.text('Balance: £2500'), findsOneWidget);
      expect(find.text('Available: £2500'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      
      final progressBar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
      expect(progressBar.value, 0.5); // 2500/5000 = 0.5
    });
  });

  group('SavingsSummary Component', () {
    testWidgets('renders savings account with formatted interest rate', (tester) async {
      final catalogItem = savingsSummaryItem();
      final mockData = {
        'payload': {
          'name': 'High Interest Savings',
          'balance': '10000.00',
          'interestRate': '2.5',
        },
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('High Interest Savings'), findsOneWidget);
      expect(find.text('Interest rate: 2.5%'), findsOneWidget);
      expect(find.text('£10000.00'), findsOneWidget);
    });
  });

}

// Mock DataModel for testing
class _MockDataModel implements DataModel {
  _MockDataModel(this._data);
  final Map<String, Object?> _data;

  @override
  Map<String, Object?> get data => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
