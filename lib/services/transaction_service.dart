import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class TransactionService {
  // Use user-specific transaction key
  static String _getTransactionsKey(String userEmail) => 'transactions_$userEmail';

  // Load transactions from SharedPreferences for specific user
  static Future<List<Transaction>> loadTransactions([String? userEmail]) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try user-specific key first, fall back to global key for backward compatibility
    String? transactionsString;
    if (userEmail != null && userEmail.isNotEmpty) {
      transactionsString = prefs.getString(_getTransactionsKey(userEmail));
      debugPrint('=== LOADING TRANSACTIONS ===');
      debugPrint('User: $userEmail');
      debugPrint('Key: ${_getTransactionsKey(userEmail)}');
      debugPrint('Raw data from SharedPreferences: $transactionsString');
    }
    
    // Fall back to global key if user-specific not found
    if (transactionsString == null) {
      transactionsString = prefs.getString('transactions');
      debugPrint('Fallback to global key - Raw data: $transactionsString');
    }

    if (transactionsString != null) {
      try {
        final List<dynamic> jsonList = json.decode(transactionsString);
        final transactions = jsonList.map((item) => Transaction.fromJson(item)).toList();
        debugPrint('Successfully loaded ${transactions.length} transactions');
        return transactions;
      } catch (e) {
        debugPrint('Error parsing transactions: $e');
        return [];
      }
    }

    debugPrint('No transactions found in storage');
    return [];
  }

  // Save transactions to SharedPreferences for specific user
  static Future<void> saveTransactions(List<Transaction> transactions, [String? userEmail]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsString = json.encode(
        transactions.map((tx) => tx.toJson()).toList(),
      );
      
      debugPrint('=== SAVING TRANSACTIONS ===');
      debugPrint('User: $userEmail');
      debugPrint('Saving ${transactions.length} transactions');
      debugPrint('Data to save: $transactionsString');
      
      // Save to both user-specific and global keys for transition period
      if (userEmail != null && userEmail.isNotEmpty) {
        await prefs.setString(_getTransactionsKey(userEmail), transactionsString);
        debugPrint('Saved to user-specific key: ${_getTransactionsKey(userEmail)}');
      }
      await prefs.setString('transactions', transactionsString);
      debugPrint('Successfully saved transactions to SharedPreferences');
    } catch (e) {
      debugPrint('Error saving transactions: $e');
      rethrow;
    }
  }

  // Clear transactions for specific user
  static Future<void> clearTransactions([String? userEmail]) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('=== CLEARING TRANSACTIONS ===');
    
    if (userEmail != null && userEmail.isNotEmpty) {
      await prefs.remove(_getTransactionsKey(userEmail));
      debugPrint('Cleared user-specific transactions for: $userEmail');
    }
    await prefs.remove('transactions');
    debugPrint('Cleared global transactions');
  }
}
