import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

CatalogItem mortgageDetailItem() {
  final schema = S.object(properties: {'payload': S.object(properties: {})}, required: ['payload']);
  return CatalogItem(
    name: 'MortgageDetail',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final payload = ((itemContext.data as Map<String, Object?>)['payload'] as Map<String, Object?>?) ?? const {};
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${payload['propertyAddress'] ?? ''}', style: Theme.of(itemContext.buildContext).textTheme.titleMedium),
            Text('Outstanding: £${payload['outstandingBalance'] ?? ''}'),
            Text('Monthly: £${payload['monthlyPayment'] ?? ''}'),
            Text('Rate: ${payload['interestRate'] ?? ''}% (${payload['rateType'] ?? ''})'),
          ]),
        ),
      );
    },
  );
}
