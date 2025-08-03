import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save user profile to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
    String? avatar,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'avatar': avatar ?? 'avatar1.png',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error saving user profile: $e');
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data() ?? {};
    } catch (e) {
      throw Exception('Error fetching user profile: $e');
    }
  }

  /// Add a transaction to Firestore
  Future<void> addTransaction({
    required String uid,
    required double amount,
    required String category,
    required DateTime date,
    required String type,
    String description = '',
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add({
            'amount': amount,
            'category': category,
            'date': date.toIso8601String(),
            'type': type,
            'description': description,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      throw Exception('Error adding transaction: $e');
    }
  }

  /// Get all transactions for a user
  Future<List<Map<String, dynamic>>> getUserTransactions(String uid) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(uid)
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching transactions: $e');
    }
  }

  /// Stream all transactions for a user
  Stream<List<Map<String, dynamic>>> streamUserTransactions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Delete a transaction
  Future<void> deleteTransaction({
    required String uid,
    required String transactionId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transactionId)
          .delete();
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }

  /// Update a transaction
  Future<void> updateTransaction({
    required String uid,
    required String transactionId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .doc(transactionId)
          .update(updates);
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }
}
