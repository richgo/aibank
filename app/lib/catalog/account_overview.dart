import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

CatalogItem accountOverviewItem() {
  final schema = S.object(properties: {
    'accounts': S.list(items: S.object(properties: {})),
    'netWorth': S.string(),
  }, required: ['accounts', 'netWorth']);

  return CatalogItem(
    name: 'AccountOverview',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final accounts = (map['accounts'] as List?) ?? const [];
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Net worth: £${map['netWorth'] ?? '0.00'}'),
            const SizedBox(height: 8),
            ...accounts.map((a) => Text('${(a as Map)['name']}: £${a['balance']}')),
          ]),
        ),
      );
    },
  );
}
