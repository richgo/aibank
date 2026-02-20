import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../theme/bank_theme.dart';

CatalogItem transactionListItem() {
  final schema = S.object(properties: {'items': S.list(items: S.object(properties: {}))}, required: ['items']);
  return CatalogItem(
    name: 'TransactionList',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final items = (map['items'] as List?) ?? const [];
      
      if (items.isEmpty) {
        return const Center(
          child: Text(
            'No transactions found',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }
      
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header row
                _buildRow(
                  'Date',
                  'Description',
                  'Amount',
                  Colors.white,
                  BankTheme.primaryGreen,
                  isHeader: true,
                ),
                // Data rows
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tx = entry.value as Map<String, Object?>;
                  
                  final date = tx['date'] as String? ?? '';
                  final description = tx['description'] as String? ?? '';
                  final amountStr = tx['amount'] as String? ?? '0';
                  final type = tx['type'] as String? ?? 'credit';
                  
                  final amount = double.tryParse(amountStr) ?? 0.0;
                  final isDebit = type == 'debit';
                  final displayAmount = isDebit ? -amount : amount;
                  
                  // Determine color
                  Color amountColor;
                  String prefix;
                  if (displayAmount > 0) {
                    amountColor = BankTheme.positive;
                    prefix = '+';
                  } else if (displayAmount < 0) {
                    amountColor = BankTheme.negative;
                    prefix = '-';
                  } else {
                    amountColor = Colors.grey;
                    prefix = '';
                  }
                  
                  final formattedAmount = '$prefix£${displayAmount.abs().toStringAsFixed(2)}';
                  final bgColor = index.isEven ? Colors.white : const Color(0xFFF5F5F5);
                  
                  return _buildRow(
                    date,
                    description,
                    formattedAmount,
                    amountColor,
                    bgColor,
                    isHeader: false,
                  );
                }),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildRow(
  String date,
  String desc,
  String amount,
  Color amountColor,
  Color bgColor,
  {required bool isHeader}
) {
  return Container(
    color: bgColor,
    child: IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Text(
                date,
                style: isHeader
                    ? const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      )
                    : const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Text(
                desc,
                style: isHeader
                    ? const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      )
                    : const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              child: Text(
                amount,
                textAlign: TextAlign.right,
                style: isHeader
                    ? const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      )
                    : TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: amountColor,
                      ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
