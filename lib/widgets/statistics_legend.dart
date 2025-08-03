import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/currency_utils.dart';

class StatisticsLegend extends StatelessWidget {
  final List<Transaction> filteredTransactions;
  final String categoryView;
  final bool sortAscending;
  final Color Function(String) getCategoryColor;
  final String displayCurrency;
  final double Function(double, String, String) convertCurrency;

  const StatisticsLegend({
    super.key,
    required this.filteredTransactions,
    required this.categoryView,
    required this.sortAscending,
    required this.getCategoryColor,
    required this.displayCurrency,
    required this.convertCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = {};
    for (var transaction in filteredTransactions) {
      if (categoryView == 'All' || transaction.type == categoryView) {
        final convertedAmount = convertCurrency(transaction.amount, transaction.currency, displayCurrency);
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + convertedAmount;
      }
    }
    final totalAmount = categoryTotals.values.fold(0.0, (sum, amount) => sum + amount);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => sortAscending ? a.value.compareTo(b.value) : b.value.compareTo(a.value));

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: sortedEntries.map((entry) {
        final percentage = (entry.value / totalAmount) * 100;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: getCategoryColor(entry.key),
              radius: 15,
            ),
            title: Text(entry.key),
            subtitle: Text('${percentage.toStringAsFixed(1)}%'),
            trailing: Text(CurrencyUtils.formatAmount(entry.value, displayCurrency)),
          ),
        );
      }).toList(),
    );
  }
}
