import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../utils/currency_utils.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final void Function(Transaction) onDelete;
  final void Function(Transaction) onEdit;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: Icon(
              transaction.type == 'Income' ? Icons.arrow_upward : Icons.arrow_downward,
              color: transaction.type == 'Income' ? Colors.green : Colors.red,
            ),
            title: Text(transaction.category),
            subtitle: Text('${CurrencyUtils.formatAmount(transaction.amount, transaction.currency)}\n${transaction.description}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEdit(transaction),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => onDelete(transaction),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}