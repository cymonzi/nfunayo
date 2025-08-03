import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nfunayo/widgets/drawer_widget.dart';
import 'package:nfunayo/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import '../models/transaction_model.dart';
import '../services/transaction_service.dart';
import '../services/sms_parser_service.dart';
import '../widgets/add_transaction_form.dart';
import 'statistics_screen.dart';
import 'auto_logged_transactions_screen.dart';
import '../widgets/home_screen_content.dart';
import 'collaborators_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userEmail,
  });

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  List<Transaction> _transactions = [];
  double _balance = 0;
  double _income = 0;
  double _expenses = 0;
  int _selectedIndex = 0;
  bool _isAddButtonVisible = false; // Initially hide the FAB
  final SmsParserService _smsService = SmsParserService();
  int _pendingSmsTransactions = 0;
  String _selectedCurrency = 'UGX'; // Default currency
  
  // Currency conversion rates (same as statistics screen)
  final Map<String, Map<String, double>> _conversionRates = {
    'USD': {'USD': 1.0, 'EUR': 0.85, 'UGX': 3700.0},
    'EUR': {'USD': 1.18, 'EUR': 1.0, 'UGX': 4350.0},
    'UGX': {'USD': 0.00027, 'EUR': 0.00023, 'UGX': 1.0},
  };

  // Convert amount from one currency to another
  double _convertCurrency(double amount, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amount;
    
    final rate = _conversionRates[fromCurrency]?[toCurrency];
    if (rate == null) {
      // If conversion rate not found, return original amount
      return amount;
    }
    return amount * rate;
  }

  late List<Widget> _widgetOptions = [
    HomeScreenContent(
      balance: _balance,
      income: _income,
      expenses: _expenses,
      transactions: _transactions,
      onDelete: _deleteTransaction,
      onEdit: _updateTransaction,
      onClearTransactions: _confirmClearTransactions,
      onAddTransaction: _showAddTransactionModal,
      isAddButtonVisible: _isAddButtonVisible,
      onToggleAddButton: _toggleAddButtonVisibility,
    ),
    StatisticsScreen(
      balance: _balance,
      income: _income,
      expenses: _expenses,
      transactions: _transactions,
      categories: [
        ...Transaction.incomeCategories,
        ...Transaction.expenseCategories,
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _initializeSmsService();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCurrency();
    }
  }

  Future<void> _refreshCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final newCurrency = prefs.getString('selectedCurrency') ?? 'UGX';
    if (newCurrency != _selectedCurrency) {
      setState(() {
        _selectedCurrency = newCurrency;
        _recalculateFinancials(); // Recalculate with new currency
        _updateWidgetOptions();
      });
    }
  }

  // Public method to refresh currency (can be called by navigation)
  void refreshCurrencySettings() {
    _refreshCurrency();
  }

  Future<void> _initializeSmsService() async {
    final initialized = await _smsService.initialize();
    if (initialized) {
      // Listen to SMS transaction stream to update badge count
      _smsService.transactionStream.listen((transaction) {
        setState(() {
          _pendingSmsTransactions++;
        });
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserEmail = prefs.getString('userEmail');
    final savedCurrency = prefs.getString('selectedCurrency') ?? 'UGX';

    setState(() {
      _selectedCurrency = savedCurrency;
    });

    debugPrint('=== LOAD USER DATA ===');
    debugPrint('Current user: ${widget.userEmail}');
    debugPrint('Saved user: $savedUserEmail');

    // Always save current user data
    await prefs.setString('userName', widget.userName);
    await prefs.setString('userEmail', widget.userEmail);
    await prefs.setString('selectedCurrency', _selectedCurrency);

    if (savedUserEmail != null && savedUserEmail != widget.userEmail) {
      // Different user - clear old user's transactions and reset
      debugPrint('Different user detected, clearing old data for: $savedUserEmail');
      await TransactionService.clearTransactions(savedUserEmail);
      setState(() {
        _transactions = [];
        _balance = 0;
        _income = 0;
        _expenses = 0;
        _isAddButtonVisible = false;
      });
    }

    // Always load transactions for current user
    debugPrint('Loading transactions for user: ${widget.userEmail}');
    await _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final loadedTransactions = await TransactionService.loadTransactions(widget.userEmail);
    setState(() {
      _transactions = loadedTransactions;
      _recalculateFinancials();
      _updateWidgetOptions();
      _isAddButtonVisible =
          _transactions.isNotEmpty; // Show FAB if transactions exist
    });
  }

  void _addTransaction(Transaction transaction) {
    setState(() {
      _transactions.add(transaction);
      _recalculateFinancials();
      TransactionService.saveTransactions(_transactions, widget.userEmail);
      _updateWidgetOptions();
      _isAddButtonVisible = true; // Show FAB after the first transaction
    });
  }

  void _updateTransaction(
    Transaction oldTransaction,
    Transaction newTransaction,
  ) {
    setState(() {
      final index = _transactions.indexOf(oldTransaction);
      _transactions[index] = newTransaction;
      _recalculateFinancials();
      TransactionService.saveTransactions(_transactions, widget.userEmail);
      _updateWidgetOptions();
    });
  }

  void _deleteTransaction(Transaction transaction) {
    setState(() {
      _transactions.remove(transaction);
      _recalculateFinancials();
      TransactionService.saveTransactions(_transactions, widget.userEmail);
      _updateWidgetOptions();
    });
  }

  void addAutoLoggedTransaction(Transaction transaction) {
    // Method to be called from auto-logged transactions screen
    _addTransaction(transaction);
  }

  void _recalculateFinancials() {
    final today = DateTime.now();
    final todayTransactions =
        _transactions.where((tx) {
          final txDate = tx.date;
          return txDate.year == today.year &&
              txDate.month == today.month &&
              txDate.day == today.day;
        }).toList();

    _income = todayTransactions
        .where((tx) => tx.type == 'Income')
        .fold(0.0, (sum, tx) => sum + _convertCurrency(tx.amount, tx.currency, _selectedCurrency));

    _expenses = todayTransactions
        .where((tx) => tx.type == 'Expense')
        .fold(0.0, (sum, tx) => sum + _convertCurrency(tx.amount, tx.currency, _selectedCurrency));

    _balance = _income - _expenses;
  }

  void _updateWidgetOptions() {
    _widgetOptions = <Widget>[
      HomeScreenContent(
        balance: _balance,
        income: _income,
        expenses: _expenses,
        transactions: _transactions,
        currency: _selectedCurrency,
        onDelete: _deleteTransaction,
        onEdit: _updateTransaction,
        onClearTransactions: _confirmClearTransactions,
        onAddTransaction: _showAddTransactionModal,
        isAddButtonVisible: _isAddButtonVisible,
        onToggleAddButton: _toggleAddButtonVisibility,
      ),
      StatisticsScreen(
        balance: _balance,
        income: _income,
        expenses: _expenses,
        transactions: _transactions,
        currency: _selectedCurrency,
        categories: [
          ...Transaction.incomeCategories,
          ...Transaction.expenseCategories,
        ],
      ),
    ];
  }

  void _toggleAddButtonVisibility() {
    setState(() {
      _isAddButtonVisible = !_isAddButtonVisible;
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    debugPrint('=== LOGOUT ===');
    debugPrint('Logging out user: ${widget.userEmail}');
    
    // Clear only session data, keep user data and transactions for persistence
    await prefs.remove('isLoggedIn');
    // Keep userName, userEmail, and selectedCurrency for transaction persistence
    
    debugPrint('Cleared session data, keeping user data for transaction persistence');
    
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder:
                  (context) => AppDrawer(
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                    notificationsEnabled: true,
                    onNotificationsToggle: (bool value) {},
                    onLogout: _logout,
                    onSettingsChanged: refreshCurrencySettings,
                  ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Lottie.asset(
              'assets/animations/avatarx.json',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text('Welcome, ${widget.userName}'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.sms),
                if (_pendingSmsTransactions > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_pendingSmsTransactions',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AutoLoggedTransactionsScreen(),
                ),
              );
              // Reset badge count when returning from screen
              setState(() {
                _pendingSmsTransactions = 0;
              });
            },
            tooltip: 'Auto-logged Transactions',
          ),
          IconButton(
            icon: const Icon(Icons.group),
            tooltip: 'Collaborators',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CollaboratorsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child:
            _widgetOptions.isNotEmpty
                ? _widgetOptions.elementAt(_selectedIndex)
                : const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton:
          _isAddButtonVisible
              ? FloatingActionButton(
                onPressed: _showAddTransactionModal,
                backgroundColor: Colors.blue,
                child: const Icon(Icons.add, color: Colors.white),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (_) => AddTransactionForm(
            onSubmit: (transaction) {
              // ignore: unnecessary_null_comparison
              if (transaction != null) {
                _addTransaction(transaction); // Add transaction and show FAB
              }
            },
            categories: [
              ...Transaction.incomeCategories,
              ...Transaction.expenseCategories,
            ],
          ),
    );
  }

  Future<void> _confirmClearTransactions() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm'),
            content: const Text(
              'Are you sure you want to clear all transactions?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (shouldClear == true) {
      await TransactionService.clearTransactions();
      _loadTransactions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsService.dispose();
    super.dispose();
  }
}
