import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

CatalogItem creditCardSummaryItem() {
  final schema = S.object(properties: {'payload': S.object(properties: {})}, required: ['payload']);
  return CatalogItem(
    name: 'CreditCardSummary',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final payload = ((itemContext.data as Map<String, Object?>)['payload'] as Map<String, Object?>?) ?? const {};
      final limit = double.tryParse('${payload['creditLimit'] ?? '0'}') ?? 0.0;
      final balance = (double.tryParse('${payload['currentBalance'] ?? '0'}') ?? 0.0).abs();
      final utilization = limit == 0 ? 0.0 : (balance / limit).clamp(0.0, 1.0);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${payload['cardNumber'] ?? ''}', style: Theme.of(itemContext.buildContext).textTheme.titleMedium),
            Text('Balance: £${payload['currentBalance'] ?? ''}'),
            Text('Available: £${payload['availableCredit'] ?? ''}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: utilization),
          ]),
        ),
      );
    },
  );
}
