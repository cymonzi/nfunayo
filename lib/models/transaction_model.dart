// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';

@immutable
class Transaction {
  final int id;
  final String description;
  final double amount;
  final String category;
  final String type;
  final DateTime date;
  final bool isAutoLogged;
  final String currency;

  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.isAutoLogged = false,
    required this.currency,
  });

  // Expanded lists for income and expense categories (Uganda context)
  static const List<String> incomeCategories = [
    'Salary',
    'Bonus',
    'Side Hustle',
    'Sales',
    'Gifts',
    'Money Received',
    'Mobile Money',
    'Farming',
    'Business',
    'House Rent',
    'Allowance',
    'Scholarship',
    'Refund',
    'Other Income',
  ];

  static const List<String> expenseCategories = [
    'House Rent',
    'Water & Electricity', 
    'Food & Drinks',
    'Transport',
    'Church & Charity',
    'Phone Bills',
    'Airtime & Data',
    'Loan Payment',
    'Bank Fees',
    'School Fees',
    'Medical',
    'Groceries',
    'Clothes & Shoes',
    'Fun & Entertainment',
    'Mobile Money Fees',
    'Farming',
    'Business Costs',
    'Savings',
    'Insurance',
    'Other Expenses',
  ];

  // Example text for description field
  static const String descriptionExample = 'e.g. Airtime for MTN, Lunch at Cafe Javas, School fees for John, Salary for July';

  // Keyword mapping for auto-categorization
  static const Map<String, String> expenseKeywordMap = {
    'juice': 'Food & Drinks',
    'restaurant': 'Food & Drinks',
    'lunch': 'Food & Drinks',
    'dinner': 'Food & Drinks',
    'cafe': 'Food & Drinks',
    'snack': 'Food & Drinks',
    'takeaway': 'Food & Drinks',
    'chips': 'Food & Drinks',
    'meat': 'Food & Drinks',
    'milk': 'Food & Drinks',
    'bread': 'Food & Drinks',
    'drink': 'Food & Drinks',
    'soda': 'Food & Drinks',
    'beer': 'Food & Drinks',
    'groceries': 'Groceries',
    'supermarket': 'Groceries',
    'market': 'Groceries',
    'vegetables': 'Groceries',
    'fruit': 'Groceries',
    'shopping': 'Groceries',
    'taxi': 'Transport',
    'boda': 'Transport',
    'fuel': 'Transport',
    'bus': 'Transport',
    'uber': 'Transport',
    'matatu': 'Transport',
    'petrol': 'Transport',
    'transport': 'Transport',
    'bodaboda': 'Transport',
    'airtime': 'Airtime & Data',
    'mtn': 'Airtime & Data',
    'airtel': 'Airtime & Data',
    'data': 'Airtime & Data',
    'internet': 'Airtime & Data',
    'bundle': 'Airtime & Data',
    'topup': 'Airtime & Data',
    'school': 'School Fees',
    'fees': 'School Fees',
    'tuition': 'School Fees',
    'education': 'School Fees',
    'university': 'School Fees',
    'college': 'School Fees',
    'hospital': 'Medical',
    'clinic': 'Medical',
    'medicine': 'Medical',
    'pharmacy': 'Medical',
    'doctor': 'Medical',
    'treatment': 'Medical',
    'movie': 'Fun & Entertainment',
    'cinema': 'Fun & Entertainment',
    'concert': 'Fun & Entertainment',
    'party': 'Fun & Entertainment',
    'event': 'Fun & Entertainment',
    'show': 'Fun & Entertainment',
    'music': 'Fun & Entertainment',
    'game': 'Fun & Entertainment',
    'umeme': 'Water & Electricity',
    'water': 'Water & Electricity',
    'electricity': 'Water & Electricity',
    'bill': 'Phone Bills',
    'yaka': 'Water & Electricity',
    'utility': 'Water & Electricity',
    'mobile money': 'Mobile Money Fees',
    'withdraw': 'Mobile Money Fees',
    'deposit': 'Mobile Money Fees',
    'transfer': 'Mobile Money Fees',
    'charge': 'Mobile Money Fees',
    'fee': 'Bank Fees',
    'clothes': 'Clothes & Shoes',
    'shirt': 'Clothes & Shoes',
    'dress': 'Clothes & Shoes',
    'shoes': 'Clothes & Shoes',
    'trousers': 'Clothes & Shoes',
    'boutique': 'Clothes & Shoes',
    'donation': 'Church & Charity',
    'church': 'Church & Charity',
    'mosque': 'Church & Charity',
    'offering': 'Church & Charity',
    'charity': 'Church & Charity',
    'tithe': 'Church & Charity',
    'stock': 'Business Costs',
    'supplies': 'Business Costs',
    'business': 'Business Costs',
    'shop': 'Business Costs',
    'wholesale': 'Business Costs',
    'retail': 'Business Costs',
    'saving': 'Savings',
    'account': 'Savings',
    'bank': 'Savings',
    'fixed': 'Savings',
    'investment': 'Savings',
    'insurance': 'Insurance',
    'premium': 'Insurance',
    'cover': 'Insurance',
    'policy': 'Insurance',
    'rent': 'House Rent',
    'loan': 'Loan Payment',
    'farming': 'Farming',
    'seeds': 'Farming',
    'fertilizer': 'Farming',
  };

  static const Map<String, String> incomeKeywordMap = {
    'salary': 'Salary',
    'wage': 'Salary',
    'pay': 'Salary',
    'bonus': 'Bonus',
    'commission': 'Bonus',
    'freelance': 'Side Hustle',
    'part time': 'Side Hustle',
    'contract': 'Side Hustle',
    'gig': 'Side Hustle',
    'sales': 'Sales',
    'sold': 'Sales',
    'gift': 'Gifts',
    'present': 'Gifts',
    'money received': 'Money Received',
    'sent money': 'Money Received',
    'transfer': 'Money Received',
    'mobile money': 'Mobile Money',
    'business': 'Business',
    'profit': 'Business',
    'rental': 'House Rent',
    'rent': 'House Rent',
    'tenant': 'House Rent',
    'scholarship': 'Scholarship',
    'bursary': 'Scholarship',
    'farming': 'Farming',
    'agriculture': 'Farming',
    'harvest': 'Farming',
    'crop': 'Farming',
    'allowance': 'Allowance',
    'pocket money': 'Allowance',
    'refund': 'Refund',
    'return': 'Refund',
    'dividend': 'Business',
  };

  // Auto-categorization function
  static String autoCategorize(String description, {bool isIncome = false}) {
    final lowerDesc = description.toLowerCase();
    final keywordMap = isIncome ? incomeKeywordMap : expenseKeywordMap;
    
    for (final entry in keywordMap.entries) {
      if (lowerDesc.contains(entry.key)) {
        return entry.value;
      }
    }
    return isIncome ? 'Other Income' : 'Other Expenses';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'category': category,
        'type': type,
        'date': date.toIso8601String(),
        'isAutoLogged': isAutoLogged,
        'currency': currency,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        description: json['description'],
        amount: json['amount'],
        category: json['category'],
        type: json['type'],
        date: DateTime.parse(json['date']),
        isAutoLogged: json['isAutoLogged'] ?? false,
        currency: json['currency'] ?? 'USD',
      );
}
