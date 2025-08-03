import '../models/transaction_model.dart';

class FinancialService {
  /// Calculates today's income, expenses, and balance from the given transactions.
  static Map<String, double> calculateFinancials(
    List<Transaction> transactions,
  ) {
    final today = DateTime.now();
    final todayTransactions =
        transactions.where((tx) {
          final txDate = tx.date;
          return txDate.year == today.year &&
              txDate.month == today.month &&
              txDate.day == today.day;
        }).toList();

    final income = todayTransactions
        .where((tx) => tx.type == 'Income') // Use the 'type' field
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final expenses = todayTransactions
        .where((tx) => tx.type == 'Expense') // Use the 'type' field
        .fold(0.0, (sum, tx) => sum + tx.amount);

    final balance = income - expenses;

    return {'income': income, 'expenses': expenses, 'balance': balance};
  }
}
