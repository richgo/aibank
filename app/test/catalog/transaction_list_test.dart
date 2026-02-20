import 'package:aibank_app/catalog/transaction_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

class _MockDataModel implements DataModel {
  _MockDataModel(this._data);
  final Map<String, Object?> _data;

  @override
  Map<String, Object?> get data => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

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
  group('TransactionList', () {
    testWidgets('shows "No transactions found" when items list is empty', (WidgetTester tester) async {
      final item = transactionListItem();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final catalogContext = _createContext(context, {'items': []});
                return item.widgetBuilder(catalogContext);
              },
            ),
          ),
        ),
      );

      expect(find.text('No transactions found'), findsOneWidget);
    });

    testWidgets('renders table with header row containing Date, Description, Amount', (WidgetTester tester) async {
      final item = transactionListItem();
      final mockData = {
        'items': [
          {
            'date': '2024-01-15',
            'description': 'Coffee Shop',
            'amount': '3.50',
            'type': 'debit',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final catalogContext = _createContext(context, mockData);
                return item.widgetBuilder(catalogContext);
              },
            ),
          ),
        ),
      );

      // Verify header text exists
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
    });

    testWidgets('formats positive amounts with green color and + prefix', (WidgetTester tester) async {
      final item = transactionListItem();
      final mockData = {
        'items': [
          {
            'date': '2024-01-15',
            'description': 'Salary',
            'amount': '2500.00',
            'type': 'credit',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final catalogContext = _createContext(context, mockData);
                return item.widgetBuilder(catalogContext);
              },
            ),
          ),
        ),
      );

      // Find the amount text
      expect(find.text('+£2500.00'), findsOneWidget);
      
      // Verify it has the correct color (BankTheme.positive)
      final textWidget = tester.widget<Text>(find.text('+£2500.00'));
      expect(textWidget.style?.color, equals(const Color(0xFF1B8A3A)));
    });

    testWidgets('formats negative amounts with red color and - prefix', (WidgetTester tester) async {
      final item = transactionListItem();
      final mockData = {
        'items': [
          {
            'date': '2024-01-15',
            'description': 'Coffee Shop',
            'amount': '3.50',
            'type': 'debit',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final catalogContext = _createContext(context, mockData);
                return item.widgetBuilder(catalogContext);
              },
            ),
          ),
        ),
      );

      // Find the amount text
      expect(find.text('-£3.50'), findsOneWidget);
      
      // Verify it has the correct color (BankTheme.negative)
      final textWidget = tester.widget<Text>(find.text('-£3.50'));
      expect(textWidget.style?.color, equals(const Color(0xFFD32F2F)));
    });

    testWidgets('renders table with scrollable container', (WidgetTester tester) async {
      final item = transactionListItem();
      final mockData = {
        'items': [
          {
            'date': '2024-01-15',
            'description': 'Transaction 1',
            'amount': '100.00',
            'type': 'credit',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                final catalogContext = _createContext(context, mockData);
                return item.widgetBuilder(catalogContext);
              },
            ),
          ),
        ),
      );

      // Verify SingleChildScrollView exists for scrolling
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      
      // Verify Column exists (table structure)
      expect(find.byType(Column), findsWidgets);
    });
  });
}
