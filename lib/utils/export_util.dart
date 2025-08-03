// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import 'error_handler.dart';

class ExportUtil {
  static Future<void> exportTransactions({
    required BuildContext context,
    required List<Transaction> transactions,
    required String selectedPeriod,
    required List<Transaction> Function(List<Transaction>, String) filterTransactions,
  }) async {
    final filteredTransactions = filterTransactions(transactions, selectedPeriod);
    
    if (filteredTransactions.isEmpty) {
      if (!context.mounted) return;
      ErrorHandler.showWarningSnackBar(
        context,
        'No transactions to export for the selected period.'
      );
      return;
    }

    // Create organized CSV content
    final csvBuffer = StringBuffer();
    
    // Header with metadata
    csvBuffer.writeln('# Transaction Export Report');
    csvBuffer.writeln('# Generated on: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    csvBuffer.writeln('# Period: $selectedPeriod');
    csvBuffer.writeln('# Total Transactions: ${filteredTransactions.length}');
    csvBuffer.writeln('');
    
    // Calculate summary statistics
    final totalIncome = filteredTransactions
        .where((tx) => tx.type == 'Income')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpenses = filteredTransactions
        .where((tx) => tx.type == 'Expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final balance = totalIncome - totalExpenses;
    
    // Summary section
    csvBuffer.writeln('# SUMMARY');
    csvBuffer.writeln('# Total Income,${totalIncome.toStringAsFixed(2)}');
    csvBuffer.writeln('# Total Expenses,${totalExpenses.toStringAsFixed(2)}');
    csvBuffer.writeln('# Net Balance,${balance.toStringAsFixed(2)}');
    csvBuffer.writeln('');
    
    // Category breakdown
    final Map<String, double> incomeByCategory = {};
    final Map<String, double> expensesByCategory = {};
    
    for (var tx in filteredTransactions) {
      if (tx.type == 'Income') {
        incomeByCategory[tx.category] = (incomeByCategory[tx.category] ?? 0) + tx.amount;
      } else {
        expensesByCategory[tx.category] = (expensesByCategory[tx.category] ?? 0) + tx.amount;
      }
    }
    
    if (incomeByCategory.isNotEmpty) {
      csvBuffer.writeln('# INCOME BY CATEGORY');
      for (var entry in incomeByCategory.entries) {
        csvBuffer.writeln('# ${entry.key},${entry.value.toStringAsFixed(2)}');
      }
      csvBuffer.writeln('');
    }
    
    if (expensesByCategory.isNotEmpty) {
      csvBuffer.writeln('# EXPENSES BY CATEGORY');
      for (var entry in expensesByCategory.entries) {
        csvBuffer.writeln('# ${entry.key},${entry.value.toStringAsFixed(2)}');
      }
      csvBuffer.writeln('');
    }
    
    // Main data table
    csvBuffer.writeln('Date,Time,Category,Type,Amount,Currency,Description');
    
    // Sort transactions by date (newest first)
    final sortedTransactions = List<Transaction>.from(filteredTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    for (var tx in sortedTransactions) {
      final date = DateFormat('yyyy-MM-dd').format(tx.date);
      final time = DateFormat('HH:mm:ss').format(tx.date);
      csvBuffer.writeln(
        '"$date","$time","${tx.category}","${tx.type}","${tx.amount.toStringAsFixed(2)}","${tx.currency}","${tx.description.replaceAll('"', '""')}"'
      );
    }
    
    final csvString = csvBuffer.toString();

    if (kIsWeb) {
      // Web: Enhanced dialog with better formatting and download option
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.download, color: Colors.blue),
              const SizedBox(width: 8),
              Text('Export Report - $selectedPeriod'),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Summary for $selectedPeriod',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Transactions: ${filteredTransactions.length}'),
                      Text('Income: ${totalIncome.toStringAsFixed(2)}'),
                      Text('Expenses: ${totalExpenses.toStringAsFixed(2)}'),
                      Text(
                        'Balance: ${balance.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: balance >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'CSV Data (copy and paste into Excel/Sheets):',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        csvString,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ErrorHandler.showInfoSnackBar(
                  context,
                  'Copy the CSV data from the dialog above and paste it into your spreadsheet application.'
                );
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy Instructions'),
            ),
          ],
        ),
      );
    } else {
      // Mobile/Desktop: save file and share
      try {
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'transactions_${selectedPeriod.toLowerCase()}_$timestamp.csv';
        final filePath = '${directory.path}/$fileName';
        final file = File(filePath);
        await file.writeAsString(csvString);
        
        await Share.shareXFiles(
          [XFile(filePath)], 
          text: 'Transaction export for $selectedPeriod period\n\nSummary:\n• ${filteredTransactions.length} transactions\n• Income: ${totalIncome.toStringAsFixed(2)}\n• Expenses: ${totalExpenses.toStringAsFixed(2)}\n• Balance: ${balance.toStringAsFixed(2)}'
        );
        
        if (!context.mounted) return;
        ErrorHandler.showSuccessSnackBar(
          context,
          'Exported $fileName successfully!'
        );
      } catch (e) {
        if (!context.mounted) return;
        ErrorHandler.showErrorSnackBar(
          context,
          'Export failed: ${e.toString()}'
        );
      }
    }
  }
}
