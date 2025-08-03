import 'package:flutter/material.dart';

class TransactionSummary extends StatelessWidget {
  final double balance;
  final double income;
  final double expenses;
  final String currency;

  const TransactionSummary({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    this.currency = 'UGX',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Colors.lightBlue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(
              Icons.account_balance_wallet, 
              'Account Balance:', 
              '$currency ${balance.toStringAsFixed(2)}'
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              Icons.arrow_upward, 
              'Total Income:', 
              '$currency ${income.toStringAsFixed(2)}', 
              color: Colors.green[700]
            ),
            _buildSummaryRow(
              Icons.arrow_downward, 
              'Total Expenditure:', 
              '$currency ${expenses.toStringAsFixed(2)}', 
              color: Colors.red[700]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.blue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(
          value, 
          style: TextStyle(
            color: color ?? Colors.blue, 
            fontWeight: FontWeight.bold
          )
        ),
      ],
    );
  }
}