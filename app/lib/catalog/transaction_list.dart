import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

CatalogItem transactionListItem() {
  final schema = S.object(properties: {'items': S.list(items: S.object(properties: {}))}, required: ['items']);
  return CatalogItem(
    name: 'TransactionList',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final items = (map['items'] as List?) ?? const [];
      if (items.isEmpty) return const Text('No transactions found');
      return Column(
        children: items.map((item) {
          final tx = item as Map<String, Object?>;
          final amount = '${tx['type'] == 'debit' ? '-' : '+'}£${tx['amount']}';
          return ListTile(
            title: Text('${tx['description'] ?? ''}'),
            subtitle: Text('${tx['date'] ?? ''}'),
            trailing: Text(amount),
          );
        }).toList(),
      );
    },
  );
}
