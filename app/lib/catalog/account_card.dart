import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme/bank_theme.dart';
import 'catalog_callbacks.dart';

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
      final accountName = map['accountName'] as String? ?? '';
      final accountType = map['accountType'] as String? ?? '';
      final balance = map['balance'] as String? ?? '0.00';
      
      return AccountCard(
        name: accountName,
        accountType: accountType,
        balance: balance,
      );
    },
  );
}

class AccountCard extends StatelessWidget {
  final String name;
  final String accountType;
  final String balance;

  const AccountCard({
    super.key,
    required this.name,
    required this.accountType,
    required this.balance,
  });

  IconData _getIconForAccountType(String type) {
    final lowerType = type.toLowerCase();
    if (lowerType.contains('checking') || lowerType.contains('current')) {
      return Icons.account_balance;
    } else if (lowerType.contains('savings')) {
      return Icons.savings;
    } else if (lowerType.contains('credit')) {
      return Icons.credit_card;
    } else if (lowerType.contains('mortgage')) {
      return Icons.home;
    }
    return Icons.account_balance; // default
  }

  @override
  Widget build(BuildContext context) {
    final isNegative = balance.startsWith('-');
    final displayBalance = balance.startsWith('-') 
        ? balance.substring(1) 
        : balance;
    final balanceColor = isNegative 
        ? const Color(0xFFFF6B6B) 
        : Colors.white;

    return SizedBox(
      width: 180,
      height: 120,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BankTheme.cardRadius),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: BankTheme.cardGradient(),
              borderRadius: BorderRadius.circular(BankTheme.cardRadius),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(BankTheme.cardRadius),
              splashColor: Colors.white.withValues(alpha: 0.3),
              onTap: () => CatalogCallbacks.onAccountDetailTap?.call(name),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top row: icon + account name
                    Row(
                      children: [
                        Icon(
                          _getIconForAccountType(accountType),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Balance
                    Text(
                      '${isNegative ? '-' : ''}£$displayBalance',
                      style: GoogleFonts.robotoMono(
                        color: balanceColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    // Account type label
                    Text(
                      accountType,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 10,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
