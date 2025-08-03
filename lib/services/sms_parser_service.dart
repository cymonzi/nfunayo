import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/transaction_model.dart';

class SmsParserService {
  static final SmsParserService _instance = SmsParserService._internal();
  factory SmsParserService() => _instance;
  SmsParserService._internal();

  StreamController<Transaction>? _transactionController;

  Stream<Transaction> get transactionStream => _transactionController!.stream;

  // Initialize SMS parsing service
  Future<bool> initialize() async {
    try {
      // Check if running on web - SMS permissions not available on web
      if (kIsWeb) {
        debugPrint('SMS Parser Service: Web platform detected, SMS features disabled');
        _transactionController = StreamController<Transaction>.broadcast();
        return false; // Return false but don't show error to user
      }

      // Request SMS permission only on mobile platforms
      final permission = await Permission.sms.request();
      if (permission != PermissionStatus.granted) {
        return false;
      }

      _transactionController = StreamController<Transaction>.broadcast();

      // For now, we'll implement basic SMS parsing without telephony package
      // In production, you would use a proper SMS listening mechanism
      debugPrint('SMS Parser Service initialized');

      return true;
    } catch (e) {
      debugPrint('Error initializing SMS parser: $e');
      // Initialize controller even on error so stream doesn't break
      _transactionController ??= StreamController<Transaction>.broadcast();
      return false;
    }
  }

  // Check if SMS permissions are available on this platform
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return false; // SMS not available on web
    }
    
    try {
      final permission = await Permission.sms.request();
      return permission == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error requesting SMS permission: $e');
      return false;
    }
  }

  // Process incoming SMS message
  void processSmsMessage(String body, String sender, DateTime date) {
    final transaction = _parseTransactionFromSms(body, sender, date);
    if (transaction != null) {
      _transactionController?.add(transaction);
    }
  }

  // Parse transaction details from SMS
  Transaction? _parseTransactionFromSms(String body, String sender, DateTime date) {
    final bodyLower = body.toLowerCase();

    // MTN Mobile Money patterns
    if (_isMtnTransaction(sender, bodyLower)) {
      return _parseMtnTransaction(bodyLower, date);
    }

    // Airtel Money patterns
    if (_isAirtelTransaction(sender, bodyLower)) {
      return _parseAirtelTransaction(bodyLower, date);
    }

    // Bank transaction patterns (generic)
    if (_isBankTransaction(sender, bodyLower)) {
      return _parseBankTransaction(bodyLower, date);
    }

    return null;
  }

  // Check if SMS is from MTN
  bool _isMtnTransaction(String sender, String body) {
    return sender.toLowerCase().contains('mtn') ||
           body.contains('mtn money') ||
           body.contains('mobile money');
  }

  // Parse MTN transaction
  Transaction? _parseMtnTransaction(String body, DateTime date) {
    try {
      // Example MTN format: "You have sent UGX 10,000 to John Doe..."
      // or "You have received UGX 5,000 from Jane..."
      
      final amountMatch = RegExp(r'ugx\s*([\d,]+)', caseSensitive: false).firstMatch(body);
      if (amountMatch == null) return null;

      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountStr) ?? 0;

      final isSent = body.contains('sent') || body.contains('paid');
      final isReceived = body.contains('received');

      String type = 'Expense';
      String category = 'Other';
      String description = 'Mobile Money Transaction';

      if (isReceived) {
        type = 'Income';
        category = 'Other';
        description = 'Mobile Money Received';
      } else if (isSent) {
        type = 'Expense';
        category = 'Transport'; // Default for mobile money
        description = 'Mobile Money Sent';
      }

      return Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        category: category,
        type: type,
        date: date,
        description: description,
        isAutoLogged: true, // Flag for auto-logged transactions
        currency: 'UGX',
      );
    } catch (e) {
      debugPrint('Error parsing MTN transaction: $e');
      return null;
    }
  }

  // Check if SMS is from Airtel
  bool _isAirtelTransaction(String sender, String body) {
    return sender.toLowerCase().contains('airtel') ||
           body.contains('airtel money');
  }

  // Parse Airtel transaction
  Transaction? _parseAirtelTransaction(String body, DateTime date) {
    try {
      // Similar logic to MTN but with Airtel-specific patterns
      final amountMatch = RegExp(r'ugx\s*([\d,]+)', caseSensitive: false).firstMatch(body);
      if (amountMatch == null) return null;

      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountStr) ?? 0;

      return Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        category: 'Other',
        type: body.contains('received') ? 'Income' : 'Expense',
        date: date,
        description: 'Airtel Money Transaction',
        isAutoLogged: true,
        currency: 'UGX',
      );
    } catch (e) {
      debugPrint('Error parsing Airtel transaction: $e');
      return null;
    }
  }

  // Check if SMS is from bank
  bool _isBankTransaction(String sender, String body) {
    final bankKeywords = ['bank', 'account', 'withdrawal', 'deposit', 'transfer'];
    return bankKeywords.any((keyword) => 
      sender.toLowerCase().contains(keyword) || body.contains(keyword));
  }

  // Parse bank transaction
  Transaction? _parseBankTransaction(String body, DateTime date) {
    try {
      final amountMatch = RegExp(r'ugx\s*([\d,]+)', caseSensitive: false).firstMatch(body);
      if (amountMatch == null) return null;

      final amountStr = amountMatch.group(1)?.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountStr) ?? 0;

      String type = 'Expense';
      String category = 'Other';

      if (body.contains('deposit') || body.contains('credit')) {
        type = 'Income';
        category = 'Salary';
      } else if (body.contains('withdrawal') || body.contains('debit')) {
        type = 'Expense';
        category = 'Bills';
      }

      return Transaction(
        id: DateTime.now().millisecondsSinceEpoch,
        amount: amount,
        category: category,
        type: type,
        date: date,
        description: 'Bank Transaction',
        isAutoLogged: true,
        currency: 'UGX',
      );
    } catch (e) {
      debugPrint('Error parsing bank transaction: $e');
      return null;
    }
  }

  // Check SMS permission status
  Future<bool> hasPermission() async {
    if (kIsWeb) {
      return false; // SMS not available on web
    }
    
    try {
      final status = await Permission.sms.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      debugPrint('Error checking SMS permission: $e');
      return false;
    }
  }

  // Dispose resources
  void dispose() {
    _transactionController?.close();
  }
}
