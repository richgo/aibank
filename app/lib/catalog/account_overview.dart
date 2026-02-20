import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../theme/bank_theme.dart';
import 'account_card.dart';

CatalogItem accountOverviewItem() {
  final schema = S.object(properties: {
    'accounts': S.list(items: S.object(properties: {})),
    'netWorth': S.string(),
  }, required: ['accounts', 'netWorth']);

  return CatalogItem(
    name: 'AccountOverview',
    dataSchema: schema,
    widgetBuilder: (CatalogItemContext itemContext) {
      final map = itemContext.data as Map<String, Object?>;
      final accounts = (map['accounts'] as List?) ?? const [];
      final netWorth = map['netWorth'] as String? ?? '0.00';
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Net worth header
          Container(
            width: double.infinity,
            color: BankTheme.primaryGreen,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Net Worth',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '£$netWorth',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Merriweather',
                  ),
                ),
              ],
            ),
          ),
          // Horizontal card list
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index] as Map<String, dynamic>;
                final accountName = account['name'] as String? ?? '';
                final accountType = (account['accountType'] ?? account['type']) as String? ?? '';
                final balance = account['balance'] as String? ?? '0.00';
                
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AccountCard(
                    name: accountName,
                    accountType: accountType,
                    balance: balance,
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
