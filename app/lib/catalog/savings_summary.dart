import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

CatalogItem savingsSummaryItem() {
  final schema = S.object(properties: {'payload': S.object(properties: {})}, required: ['payload']);
  return CatalogItem(
    name: 'SavingsSummary',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final payload = ((itemContext.data as Map<String, Object?>)['payload'] as Map<String, Object?>?) ?? const {};
      return Card(
        child: ListTile(
          title: Text('${payload['name'] ?? 'Savings'}'),
          subtitle: Text('Interest rate: ${payload['interestRate'] ?? ''}%'),
          trailing: Text('£${payload['balance'] ?? ''}'),
        ),
      );
    },
  );
}
