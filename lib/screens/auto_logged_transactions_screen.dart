// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/sms_parser_service.dart';
import '../services/transaction_service.dart';
import '../utils/currency_utils.dart';
import 'package:intl/intl.dart';

class AutoLoggedTransactionsScreen extends StatefulWidget {
  const AutoLoggedTransactionsScreen({super.key});

  @override
  State<AutoLoggedTransactionsScreen> createState() => _AutoLoggedTransactionsScreenState();
}

class _AutoLoggedTransactionsScreenState extends State<AutoLoggedTransactionsScreen> {
  final SmsParserService _smsService = SmsParserService();
  final List<Transaction> _pendingTransactions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeSmsService();
  }

  Future<void> _initializeSmsService() async {
    setState(() => _isLoading = true);
    
    try {
      final initialized = await _smsService.initialize();
      if (initialized) {
        // Listen to auto-logged transactions
        _smsService.transactionStream.listen((transaction) {
          if (mounted) {
            setState(() {
              _pendingTransactions.add(transaction);
            });
          }
        });
      } else if (!kIsWeb) {
        // Only show permission dialog on mobile platforms
        _showPermissionDialog();
      }
    } catch (e) {
      debugPrint('Error initializing SMS service: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SMS Permission Required'),
        content: const Text(
          'To automatically capture transactions from SMS alerts, '
          'please grant SMS reading permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final granted = await _smsService.requestPermission();
              if (granted) {
                _initializeSmsService();
              }
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _confirmTransaction(Transaction transaction) async {
    // Add transaction to main transaction list via TransactionService
    final allTransactions = await TransactionService.loadTransactions();
    allTransactions.add(transaction);
    await TransactionService.saveTransactions(allTransactions);
    
    setState(() {
      _pendingTransactions.remove(transaction);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction confirmed and added!')),
    );
  }

  void _editTransaction(Transaction transaction) {
    _showEditDialog(transaction);
  }

  void _deleteTransaction(Transaction transaction) {
    setState(() {
      _pendingTransactions.remove(transaction);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction dismissed')),
    );
  }

  void _showEditDialog(Transaction transaction) {
    final amountController = TextEditingController(text: transaction.amount.toString());
    final descriptionController = TextEditingController(text: transaction.description);
    String selectedCategory = transaction.category;
    String selectedType = transaction.type;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Transaction'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const [
                  DropdownMenuItem(value: 'Income', child: Text('Income')),
                  DropdownMenuItem(value: 'Expense', child: Text('Expense')),
                ],
                onChanged: (value) {
                  selectedType = value!;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: (selectedType == 'Income' 
                    ? Transaction.incomeCategories 
                    : Transaction.expenseCategories)
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final updatedTransaction = Transaction(
                id: transaction.id,
                amount: double.tryParse(amountController.text) ?? transaction.amount,
                description: descriptionController.text,
                category: selectedCategory,
                type: selectedType,
                date: transaction.date,
                isAutoLogged: true,
                currency: transaction.currency,
              );
              Navigator.pop(context);
              _confirmTransaction(updatedTransaction);
            },
            child: const Text('Save & Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryBlue = Colors.blue;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Logged Transactions'),
        backgroundColor: primaryBlue,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingTransactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sms, size: 64, color: primaryBlue),
                      SizedBox(height: 16),
                      Text(
                        kIsWeb ? 'SMS feature not available on web' : 'No pending transactions',
                        style: TextStyle(fontSize: 18, color: primaryBlue, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        kIsWeb 
                            ? 'This feature works on mobile devices only'
                            : 'Transactions will appear here when detected from SMS',
                        style: TextStyle(color: Colors.blueGrey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _pendingTransactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: transaction.type == 'Income'
                                        ? primaryBlue.withOpacity(0.1)
                                        : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    transaction.type,
                                    style: TextStyle(
                                      color: transaction.type == 'Income'
                                          ? primaryBlue
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  CurrencyUtils.formatAmount(transaction.amount, transaction.currency),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              transaction.description,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${transaction.category} • ${DateFormat.yMMMd().format(transaction.date)}',
                              style: TextStyle(
                                color: primaryBlue.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _editTransaction(transaction),
                                    icon: Icon(Icons.edit, color: primaryBlue),
                                    label: Text('Edit', style: TextStyle(color: primaryBlue)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: primaryBlue),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _deleteTransaction(transaction),
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    label: const Text('Dismiss', style: TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _confirmTransaction(transaction),
                                    icon: Icon(Icons.check, color: Colors.white),
                                    label: const Text('Confirm'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: !kIsWeb ? FloatingActionButton(
        onPressed: () {
          // Demo: simulate an SMS transaction
          final demoTransaction = Transaction(
            id: DateTime.now().millisecondsSinceEpoch,
            amount: 50000,
            description: 'MTN Mobile Money - Sent to John Doe',
            category: 'Transport',
            type: 'Expense',
            date: DateTime.now(),
            isAutoLogged: true,
            currency: 'USD',
          );
          setState(() {
            _pendingTransactions.add(demoTransaction);
          });
        },
        tooltip: 'Add Demo Transaction',
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  @override
  void dispose() {
    _smsService.dispose();
    super.dispose();
  }
}
