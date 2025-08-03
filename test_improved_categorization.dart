import 'lib/models/transaction_model.dart';

void main() {
  
  // Test expense examples with everyday Ugandan terms
  final expenseTests = [
    'Lunch at Cafe Javas',
    'MTN airtime 10,000',
    'Bodaboda to office', 
    'School fees for Sarah',
    'Medicine from pharmacy',
    'Shopping at Nakumatt',
    'Movie at Century Cinemax',
    'Church offering Sunday',
    'New shoes from Bata',
    'UMEME yaka tokens',
    'Mobile money withdrawal fee',
    'Maize seeds for planting',
    'Random stuff',
  ];
  
  for (final description in expenseTests) {
    final _ = Transaction.autoCategorize(description, isIncome: false);
  }
  
  // Test income examples with simple terms
  final incomeTests = [
    'Monthly salary payment',
    'Bonus from company',
    'Part time teaching job',
    'Sold old phone',
    'Gift from grandma',
    'Money sent from brother',
    'Mobile money from client',
    'Business profit this month',
    'Rent from tenant',
    'Scholarship from university',
    'Harvest maize sales',
    'Pocket money from dad',
    'Refund from shop',
    'Something else',
  ];
  
  for (final description in incomeTests) {
    final _ = Transaction.autoCategorize(description, isIncome: true);
  }
  
}
