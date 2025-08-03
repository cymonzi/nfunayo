import 'dart:async';
import 'package:flutter/foundation.dart'; // For debugging or platform-specific checks

/// A utility function to handle futures with error handling.
Future<T> handleThenable<T>(Future<T> future) async {
  try {
    return await future;
  } catch (e, stackTrace) {
    // Log the error or handle it appropriately
    if (kDebugMode) {
      print('Error in handleThenable: $e');
      print('StackTrace: $stackTrace');
    }
    rethrow; // Re-throw the error after logging
  }
}
