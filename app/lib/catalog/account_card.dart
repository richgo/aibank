import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

CatalogItem accountCardItem() {
  final schema = S.object(properties: {
    'accountName': S.string(),
    'accountType': S.string(),
    'balance': S.string(),
    'currency': S.string(),
  }, required: ['accountName', 'accountType', 'balance', 'currency']);

  return CatalogItem(
    name: 'AccountCard',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final balance = (map['balance'] as String?) ?? '0.00';
      final isNegative = balance.startsWith('-');
      return Card(
        child: ListTile(
          title: Text('${map['accountName'] ?? ''}'),
          subtitle: Text('${map['accountType'] ?? ''}'),
          trailing: Text('£$balance', style: TextStyle(color: isNegative ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
        ),
      );
    },
  );
}
