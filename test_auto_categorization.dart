import 'lib/models/transaction_model.dart';

void main() {
  // Test auto-categorization examples
  
  // Expense examples
  final expenseTests = [
    'Lunch at Cafe Javas',
    'MTN airtime topup',
    'Taxi to work',
    'School fees for John',
    'Hospital visit',
    'Groceries at supermarket',
    'Movie tickets',
    'Church offering',
    'New shirt from boutique',
    'UMEME electricity bill',
  ];
  
  for (final description in expenseTests) {
    Transaction.autoCategorize(description, isIncome: false);
  }
  
  // Income examples
  final incomeTests = [
    'Monthly salary',
    'Freelance project payment',
    'Sales commission',
    'Gift from uncle',
    'Rental income from property',
    'Scholarship payment',
    'Business profit',
    'Agriculture harvest sale',
  ];
  
  for (final description in incomeTests) {
    Transaction.autoCategorize(description, isIncome: true);
  }
  
}
