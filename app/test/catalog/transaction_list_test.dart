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
  });
}
