import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme/bank_theme.dart';
import 'catalog_callbacks.dart';
import 'catalog_utils.dart';
import 'transaction_list.dart';

CatalogItem accountDetailViewItem() {
  final schema = S.object(properties: {
    'name': S.string(),
    'type': S.string(),
    'balance': S.string(),
    'currency': S.string(),
    'accountNumber': S.string(),
    'sortCode': S.string(),
    'interestRate': S.string(),
    'overdraftLimit': S.string(),
    'transactions': S.list(items: S.object(properties: {})),
  });

  return CatalogItem(
    name: 'AccountDetailView',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final ctx = itemContext.dataContext;
      final name = resolveValue<String>(ctx, map['name']) ?? '';
      final type = resolveValue<String>(ctx, map['type']) ?? '';
      final balance = resolveValue<String>(ctx, map['balance']) ?? '0.00';
      final accountNumber = resolveValue<String>(ctx, map['accountNumber']);
      final sortCode = resolveValue<String>(ctx, map['sortCode']);
      final interestRate = resolveValue<String>(ctx, map['interestRate']);
      final overdraftLimit = resolveValue<String>(ctx, map['overdraftLimit']);
      final transactions = resolveList(ctx, map['transactions']);

      final isNegative = balance.startsWith('-');
      final displayBalance = isNegative ? balance.substring(1) : balance;

      final details = <({String label, String value})>[
        if (accountNumber != null) (label: 'Account No.', value: accountNumber),
        if (sortCode != null) (label: 'Sort Code', value: sortCode),
        if (interestRate != null) (label: 'Interest Rate', value: '$interestRate%'),
        if (overdraftLimit != null) (label: 'Overdraft', value: '£$overdraftLimit'),
      ];

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with back button, name, and balance
          Container(
            decoration: BoxDecoration(
              gradient: BankTheme.cardGradient(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BankTheme.panelRadius),
                topRight: Radius.circular(BankTheme.panelRadius),
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => CatalogCallbacks.onBackToOverview?.call(),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text('Accounts', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.merriweather(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            type,
                            style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Balance',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${isNegative ? '-' : ''}£$displayBalance',
                          style: GoogleFonts.robotoMono(
                            color: isNegative ? const Color(0xFFFF8A80) : Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Account details chips
          if (details.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Wrap(
                spacing: 28,
                runSpacing: 10,
                children: details
                    .map((d) => _DetailItem(label: d.label, value: d.value))
                    .toList(),
              ),
            ),
          // Divider before transactions
          if (transactions.isNotEmpty) ...[
            Container(
              color: BankTheme.backgroundLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Recent Transactions',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: transactions.asMap().entries.map((e) {
                  final tx = e.value as Map<String, Object?>;
                  return TransactionRow(tx: tx, isLast: e.key == transactions.length - 1);
                }).toList(),
              ),
            ),
          ],
        ],
      );
    },
  );
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  const _DetailItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 14, color: BankTheme.textDark, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
