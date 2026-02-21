import 'package:aibank_app/catalog/account_card.dart';
import 'package:aibank_app/catalog/account_overview.dart';
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
      expect(accountCardItem().name, 'AccountCard');
      expect(transactionListItem().name, 'TransactionList');
      expect(mortgageDetailItem().name, 'MortgageDetail');
      expect(creditCardSummaryItem().name, 'CreditCardSummary');
      expect(savingsSummaryItem().name, 'SavingsSummary');
      expect(accountOverviewItem().name, 'AccountOverview');
    });
  });

  group('AccountCard Component', () {
    testWidgets('renders account name, type, and balance with correct styling', (tester) async {
      final catalogItem = accountCardItem();
      final mockData = {
        'accountName': 'Main Current Account',
        'accountType': 'Checking',
        'balance': '1234.56',
        'currency': 'GBP',
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('Main Current Account'), findsOneWidget);
      expect(find.text('Checking'), findsOneWidget);
      expect(find.text('£1234.56'), findsOneWidget);
      
      // Check that the card has the correct dimensions
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 180);
      expect(sizedBox.height, 120);
      
      // Check for account balance icon
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('renders negative balance in coral color', (tester) async {
      final catalogItem = accountCardItem();
      final mockData = {
        'accountName': 'Overdraft Account',
        'accountType': 'Checking',
        'balance': '-500.00',
        'currency': 'GBP',
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      expect(find.text('-£500.00'), findsOneWidget);
      
      // Check that negative balance is rendered in coral color
      final balanceText = tester.widget<Text>(find.text('-£500.00'));
      expect(balanceText.style?.color, const Color(0xFFFF6B6B));
    });

    testWidgets('shows correct icon for different account types', (tester) async {
      final catalogItem = accountCardItem();
      
      // Test savings icon
      final savingsWidget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, {
              'accountName': 'Savings Account',
              'accountType': 'Savings',
              'balance': '5000.00',
              'currency': 'GBP',
            })),
          ),
        ),
      );
      
      await tester.pumpWidget(savingsWidget);
      expect(find.byIcon(Icons.savings), findsOneWidget);
      
      // Test credit card icon
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, {
              'accountName': 'Credit Card',
              'accountType': 'Credit',
              'balance': '-1000.00',
              'currency': 'GBP',
            })),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.credit_card), findsOneWidget);
      
      // Test mortgage icon
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, {
              'accountName': 'Home Loan',
              'accountType': 'Mortgage',
              'balance': '-250000.00',
              'currency': 'GBP',
            })),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('has gradient background and tappable gesture detector', (tester) async {
      final catalogItem = accountCardItem();
      final mockData = {
        'accountName': 'Test Account',
        'accountType': 'Checking',
        'balance': '100.00',
        'currency': 'GBP',
      };

      final widget = MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => catalogItem.widgetBuilder(_createContext(context, mockData)),
          ),
        ),
      );

      await tester.pumpWidget(widget);

      // Check for GestureDetector with opaque hit testing
      expect(find.byType(GestureDetector), findsOneWidget);
      
      // Check for gradient via DecoratedBox widget
      expect(find.byType(DecoratedBox), findsOneWidget);
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

  group('AccountOverview Component', () {
    testWidgets('renders net worth header and horizontal account cards', (tester) async {
      final catalogItem = accountOverviewItem();
      final mockData = {
        'netWorth': '15234.56',
        'accounts': [
          {'name': 'Current', 'balance': '1234.56', 'accountType': 'Checking'},
          {'name': 'My Savings', 'balance': '10000.00', 'accountType': 'Savings'},
          {'name': 'Credit Card', 'balance': '-4000.00', 'accountType': 'Credit'},
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

      // Check net worth header
      expect(find.text('Net Worth'), findsOneWidget);
      expect(find.text('£15234.56'), findsOneWidget);
      
      // Check account cards are rendered
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('My Savings'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      
      // Check account types are displayed
      expect(find.text('Checking'), findsOneWidget);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Credit'), findsOneWidget);
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
