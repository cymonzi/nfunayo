import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nfunayo/widgets/add_transaction_form.dart';
import '../models/transaction_model.dart';
import '../utils/currency_utils.dart';
import 'transaction_summary.dart';
import 'package:intl/intl.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.transactions,
    required this.onDelete,
    required this.onEdit,
    required this.onClearTransactions,
    required this.onAddTransaction,
    required this.isAddButtonVisible,
    required this.onToggleAddButton,
    this.currency = 'UGX',
  });

  final double balance;
  final double income;
  final double expenses;
  final List<Transaction> transactions;
  final void Function(Transaction) onDelete;
  final void Function(Transaction, Transaction) onEdit;
  final VoidCallback onClearTransactions;
  final VoidCallback onAddTransaction;
  final bool isAddButtonVisible;
  final VoidCallback onToggleAddButton;
  final String currency;

  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenContentState createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  String _selectedPeriod = 'Daily';

  List<Transaction> _filterTransactions(String period) {
    DateTime now = DateTime.now();
    List<Transaction> filteredTransactions = [];

    switch (period) {
      case 'Daily':
        filteredTransactions =
            widget.transactions.where((transaction) {
              return transaction.date.day == now.day &&
                  transaction.date.month == now.month &&
                  transaction.date.year == now.year;
            }).toList();
        break;
      case 'Weekly':
        DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        filteredTransactions =
            widget.transactions.where((transaction) {
              return transaction.date.isAfter(startOfWeek) &&
                  transaction.date.isBefore(now.add(const Duration(days: 1)));
            }).toList();
        break;
      case 'Monthly':
        filteredTransactions =
            widget.transactions.where((transaction) {
              return transaction.date.month == now.month &&
                  transaction.date.year == now.year;
            }).toList();
        break;
      case 'Yearly':
        filteredTransactions =
            widget.transactions.where((transaction) {
              return transaction.date.year == now.year;
            }).toList();
        break;
    }

    return filteredTransactions;
  }

  @override
  Widget build(BuildContext context) {
    List<Transaction> filteredTransactions = _filterTransactions(
      _selectedPeriod,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TransactionSummary(
            balance: widget.balance,
            income: widget.income,
            expenses: widget.expenses,
            currency: widget.currency,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Transactions by Period',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: widget.onClearTransactions,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueGrey),
            ),
            child: DropdownButton<String>(
              value: _selectedPeriod,
              onChanged: (value) {
                setState(() {
                  _selectedPeriod = value!;
                });
              },
              isExpanded: true,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'Yearly', child: Text('Yearly')),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              // Add pull-to-refresh logic if needed
            },
            child:
                filteredTransactions.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Click the button below to add a transaction',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () {
                              widget
                                  .onToggleAddButton(); // Show Add button in navigation
                              widget
                                  .onAddTransaction(); // Trigger add transaction callback
                            },
                            child: Lottie.asset(
                              'assets/animations/add.json',
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = filteredTransactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: ListTile(
                            leading: Icon(
                              transaction.type == 'Income'
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              color:
                                  transaction.type == 'Income'
                                      ? Colors.green
                                      : Colors.red,
                            ),
                            title: Text(
                              transaction.category,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  CurrencyUtils.formatAmount(transaction.amount, transaction.currency),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  transaction.description,
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Expected Date: ${DateFormat.yMd().format(transaction.date)}',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      builder:
                                          (_) => AddTransactionForm(
                                            initialTransaction: transaction,
                                            onSubmit:
                                                (newTransaction) =>
                                                    widget.onEdit(
                                                      transaction,
                                                      newTransaction,
                                                    ),
                                            categories:
                                                transaction.type == 'Income'
                                                    ? Transaction
                                                        .incomeCategories
                                                    : Transaction
                                                        .expenseCategories,
                                          ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => widget.onDelete(transaction),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}
