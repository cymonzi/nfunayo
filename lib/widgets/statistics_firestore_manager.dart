// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

/// A widget that displays Firestore transaction data in the statistics screen
class StatisticsFirestoreManager extends StatefulWidget {
  final Function(List<Transaction>) onTransactionsLoaded;

  const StatisticsFirestoreManager({
    super.key,
    required this.onTransactionsLoaded,
  });

  @override
  State<StatisticsFirestoreManager> createState() => _StatisticsFirestoreManagerState();
}

class _StatisticsFirestoreManagerState extends State<StatisticsFirestoreManager> {
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFirestoreData();
  }

  Future<void> _loadFirestoreData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = '';
      });
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('Loading Firestore transactions for statistics screen: ${user.email}');
        final transactions = await TransactionService.loadTransactions(user.email);
        
        if (mounted) {
          widget.onTransactionsLoaded(transactions);
          setState(() => _isLoading = false);
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Not logged in';
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading Firestore data for statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load data: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This widget is not visible, just manages data loading
    return const SizedBox.shrink();
  }
}
