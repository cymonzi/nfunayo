import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction_model.dart';
import 'firestore_service.dart';

class TransactionService {
  static const _transactionsKey = 'transactions';
  static final FirestoreService _firestoreService = FirestoreService();

  // Generate user-specific key for local storage fallback
  static String _getUserTransactionsKey(String userEmail) => 'transactions_$userEmail';

  // Load transactions from Firestore with SharedPreferences fallback
  static Future<List<Transaction>> loadTransactions([String? userEmail]) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        debugPrint('Loading transactions from Firestore for user: ${user.email}');
        
        // Load from Firestore
        final firestoreTransactions = await _firestoreService.getUserTransactions(user.uid);
        final transactions = firestoreTransactions.map((data) {
          // Convert Firestore data to Transaction model format
          return Transaction(
            id: int.tryParse(data['id'] ?? '') ?? DateTime.now().millisecondsSinceEpoch,
            amount: (data['amount'] as num).toDouble(),
            category: data['category'] ?? '',
            description: data['description'] ?? '',
            date: DateTime.parse(data['date']),
            type: data['type'] ?? 'expense',
            currency: data['currency'] ?? 'UGX',
            isAutoLogged: data['isAutoLogged'] ?? false,
          );
        }).toList();
        
        debugPrint('Loaded ${transactions.length} transactions from Firestore');
        
        // Also save to local storage for offline access
        await _saveToLocalStorage(transactions, userEmail);
        
        return transactions;
      }
    } catch (e) {
      debugPrint('Error loading from Firestore, falling back to local storage: $e');
    }
    
    // Fallback to SharedPreferences if Firestore fails or user not authenticated
    return await _loadFromLocalStorage(userEmail);
  }

  // Save transactions to Firestore with SharedPreferences backup
  static Future<void> saveTransactions(List<Transaction> transactions, [String? userEmail]) async {
    debugPrint('Saving ${transactions.length} transactions');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        debugPrint('Saving transactions to Firestore for user: ${user.email}');
        
        // Note: For now, we'll sync all transactions to Firestore
        // In a production app, you'd want to track which transactions are new/modified
        // and only sync those to avoid unnecessary writes
        
        // For simplicity, we'll clear and re-add all transactions
        // This is not optimal but ensures data consistency
        final userTransactionsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions');
            
        // Get existing transactions to delete them
        final existingDocs = await userTransactionsRef.get();
        for (final doc in existingDocs.docs) {
          await doc.reference.delete();
        }
        
        // Add all current transactions
        for (final transaction in transactions) {
          await userTransactionsRef.add({
            'id': transaction.id.toString(),
            'amount': transaction.amount,
            'category': transaction.category,
            'date': transaction.date.toIso8601String(),
            'type': transaction.type,
            'description': transaction.description,
            'currency': transaction.currency,
            'isAutoLogged': transaction.isAutoLogged,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        
        debugPrint('Successfully saved transactions to Firestore');
      }
    } catch (e) {
      debugPrint('Error saving to Firestore: $e');
    }
    
    // Always save to local storage as backup
    await _saveToLocalStorage(transactions, userEmail);
  }

  // Clear transactions from both Firestore and local storage
  static Future<void> clearTransactions([String? userEmail]) async {
    debugPrint('Clearing transactions');
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        debugPrint('Clearing transactions from Firestore for user: ${user.email}');
        
        final userTransactionsRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions');
            
        final existingDocs = await userTransactionsRef.get();
        for (final doc in existingDocs.docs) {
          await doc.reference.delete();
        }
        
        debugPrint('Cleared transactions from Firestore');
      }
    } catch (e) {
      debugPrint('Error clearing from Firestore: $e');
    }
    
    // Clear from local storage
    await _clearLocalStorage(userEmail);
  }

  // Helper method to load from SharedPreferences
  static Future<List<Transaction>> _loadFromLocalStorage([String? userEmail]) async {
    final prefs = await SharedPreferences.getInstance();
    String transactionsString = '';
    
    // Try user-specific key first if userEmail is provided
    if (userEmail != null && userEmail.isNotEmpty) {
      transactionsString = prefs.getString(_getUserTransactionsKey(userEmail)) ?? '';
      debugPrint('Loading from local storage for user: $userEmail');
    }
    
    // Fall back to global key if user-specific not found
    if (transactionsString.isEmpty) {
      transactionsString = prefs.getString(_transactionsKey) ?? '';
      debugPrint('Falling back to global transactions key');
    }

    if (transactionsString.isNotEmpty) {
      try {
        final List<dynamic> jsonList = json.decode(transactionsString);
        final transactions = jsonList.map((item) => Transaction.fromJson(item)).toList();
        debugPrint('Loaded ${transactions.length} transactions from local storage');
        return transactions;
      } catch (e) {
        debugPrint('Error parsing local transactions: $e');
        return [];
      }
    }

    debugPrint('No transactions found in local storage');
    return [];
  }

  // Helper method to save to SharedPreferences
  static Future<void> _saveToLocalStorage(List<Transaction> transactions, [String? userEmail]) async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = json.encode(
      transactions.map((tx) => tx.toJson()).toList(),
    );
    
    debugPrint('Saving to local storage');
    
    // Save to user-specific key if userEmail is provided
    if (userEmail != null && userEmail.isNotEmpty) {
      await prefs.setString(_getUserTransactionsKey(userEmail), transactionsString);
      debugPrint('Saved to user-specific local key: ${_getUserTransactionsKey(userEmail)}');
    } else {
      // Save to global key for backward compatibility
      await prefs.setString(_transactionsKey, transactionsString);
      debugPrint('Saved to global local key');
    }
  }

  // Helper method to clear from SharedPreferences
  static Future<void> _clearLocalStorage([String? userEmail]) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (userEmail != null && userEmail.isNotEmpty) {
      await prefs.remove(_getUserTransactionsKey(userEmail));
      debugPrint('Cleared local storage for user: $userEmail');
    } else {
      await prefs.remove(_transactionsKey);
      debugPrint('Cleared global local storage');
    }
  }
}
