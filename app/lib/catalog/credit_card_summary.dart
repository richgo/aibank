import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bank_theme.dart';

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
      return Container(
        decoration: BoxDecoration(
          gradient: BankTheme.cardGradient(),
          borderRadius: BorderRadius.circular(BankTheme.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${payload['cardNumber'] ?? ''}',
              style: GoogleFonts.merriweather(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Balance: £${payload['currentBalance'] ?? ''}',
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'Available: £${payload['availableCredit'] ?? ''}',
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: utilization,
                color: BankTheme.accentCoral,
                backgroundColor: Colors.white30,
                minHeight: 6,
              ),
            ),
          ]),
        ),
      );
    },
  );
}
