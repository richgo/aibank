import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../theme/bank_theme.dart';
import 'catalog_callbacks.dart';
import 'catalog_utils.dart';

CatalogItem transactionListItem() {
  final schema = S.object(
    properties: {
      'items': S.list(items: S.object(properties: {})),
      'accountName': S.string(),
    },
    required: ['items'],
  );
  return CatalogItem(
    name: 'TransactionList',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final items = resolveList(itemContext.dataContext, map['items']);
      final accountName = resolveValue<String>(itemContext.dataContext, map['accountName']) ?? 'Account';

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            decoration: BoxDecoration(
              gradient: BankTheme.cardGradient(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(BankTheme.panelRadius),
                topRight: Radius.circular(BankTheme.panelRadius),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => CatalogCallbacks.onBackToOverview?.call(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Accounts',
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    accountName,
                    style: GoogleFonts.merriweather(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${items.length} transactions',
                  style: GoogleFonts.inter(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          // Transaction rows
          if (items.isEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text('No transactions found', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: items.asMap().entries.map((entry) {
                  final tx = entry.value as Map<String, Object?>;
                  final isLast = entry.key == items.length - 1;
                  return TransactionRow(tx: tx, isLast: isLast);
                }).toList(),
              ),
            ),
        ],
      );
    },
  );
}

class TransactionRow extends StatelessWidget {
  final Map<String, Object?> tx;
  final bool isLast;

  const TransactionRow({required this.tx, required this.isLast});

  static IconData _iconFor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('tesco') || d.contains('m&s') || d.contains('waitrose') || d.contains('sainsbury')) {
      return Icons.shopping_cart_outlined;
    } else if (d.contains('transport') || d.contains('rail') || d.contains('bus') || d.contains('tfl')) {
      return Icons.directions_bus_outlined;
    } else if (d.contains('coffee') || d.contains('pret') || d.contains('costa') || d.contains('cafe')) {
      return Icons.local_cafe_outlined;
    } else if (d.contains('energy') || d.contains('electric') || d.contains('gas') || d.contains('octopus')) {
      return Icons.bolt_outlined;
    } else if (d.contains('council') || d.contains('tax') || d.contains('rates')) {
      return Icons.account_balance_outlined;
    } else if (d.contains('spotify') || d.contains('apple music') || d.contains('music')) {
      return Icons.music_note_outlined;
    } else if (d.contains('amazon') || d.contains('ebay') || d.contains('delivery')) {
      return Icons.inventory_2_outlined;
    } else if (d.contains('boots') || d.contains('pharmacy') || d.contains('chemist')) {
      return Icons.local_pharmacy_outlined;
    }
    return Icons.receipt_outlined;
  }

  static Color _iconColor(String type) =>
      type == 'debit' ? BankTheme.negative : BankTheme.positive;

  @override
  Widget build(BuildContext context) {
    final description = tx['description'] as String? ?? '';
    final dateStr = tx['date'] as String? ?? '';
    final amountStr = tx['amount'] as String? ?? '0';
    final type = tx['type'] as String? ?? 'debit';
    final isDebit = type == 'debit';
    final amount = double.tryParse(amountStr) ?? 0.0;
    final displayAmt = isDebit ? '-£${amount.toStringAsFixed(2)}' : '+£${amount.toStringAsFixed(2)}';
    final amountColor = isDebit ? BankTheme.negative : BankTheme.positive;

    // Format date: "2026-02-20" → "20 Feb"
    String formattedDate = dateStr;
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = int.tryParse(parts[1]) ?? 0;
        formattedDate = '${parts[2]} ${months[month]}';
      }
    } catch (_) {}

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _iconColor(type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(description), size: 18, color: _iconColor(type)),
              ),
              const SizedBox(width: 12),
              // Description + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: BankTheme.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              // Amount
              Text(
                displayAmt,
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, indent: 68, endIndent: 16, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}
