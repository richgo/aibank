import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bank_theme.dart';

CatalogItem savingsSummaryItem() {
  final schema = S.object(properties: {'payload': S.object(properties: {})}, required: ['payload']);
  return CatalogItem(
    name: 'SavingsSummary',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final payload = ((itemContext.data as Map<String, Object?>)['payload'] as Map<String, Object?>?) ?? const {};
      return Card(
        color: const Color(0xFFE8F5E9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BankTheme.panelRadius),
        ),
        elevation: BankTheme.elevationResting,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${payload['name'] ?? 'Savings'}',
                style: GoogleFonts.merriweather(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BankTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: BankTheme.accentCoral,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  'Interest rate: ${payload['interestRate'] ?? ''}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '£${payload['balance'] ?? ''}',
                style: GoogleFonts.robotoMono(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BankTheme.positive,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
