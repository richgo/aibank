import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/bank_theme.dart';

CatalogItem mortgageDetailItem() {
  final schema = S.object(properties: {'payload': S.object(properties: {})}, required: ['payload']);
  return CatalogItem(
    name: 'MortgageDetail',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final payload = ((itemContext.data as Map<String, Object?>)['payload'] as Map<String, Object?>?) ?? const {};
      
      Widget buildDataRow(String label, String value, bool isAlternate, {bool isCurrency = false}) {
        return Container(
          color: isAlternate ? const Color(0xFFF5F5F5) : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: BankTheme.textDark,
                ).merge(
                  isCurrency ? GoogleFonts.robotoMono(color: BankTheme.primaryGreen) : null,
                ),
              ),
            ],
          ),
        );
      }
      
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BankTheme.panelRadius),
        ),
        elevation: BankTheme.elevationResting,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '${payload['propertyAddress'] ?? 'Mortgage'}',
                style: GoogleFonts.merriweather(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BankTheme.primaryGreen,
                ),
              ),
            ),
            buildDataRow('Outstanding Balance', '£${payload['outstandingBalance'] ?? ''}', false, isCurrency: true),
            buildDataRow('Monthly Payment', '£${payload['monthlyPayment'] ?? ''}', true, isCurrency: true),
            buildDataRow('Interest Rate', '${payload['interestRate'] ?? ''}% (${payload['rateType'] ?? ''})', false),
          ],
        ),
      );
    },
  );
}
