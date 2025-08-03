import 'package:flutter/material.dart';
// import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_summary.dart';
import '../widgets/statistics_legend.dart';
import '../utils/export_util.dart';
import '../utils/currency_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/transaction_service.dart';

class StatisticsScreen extends StatefulWidget {
  final double balance;
  final double income;
  final double expenses;
  final List<Transaction> transactions;
  final List<String> categories;
  final String currency;

  const StatisticsScreen({
    super.key,
    required this.balance,
    required this.income,
    required this.expenses,
    required this.transactions,
    required this.categories,
    this.currency = 'UGX',
  });

  @override
  // ignore: library_private_types_in_public_api
  _StatisticsScreenState createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Daily';
  String _categoryView = 'All'; // New: Filter for All, Income, or Expense
  bool _sortAscending = true;
  late double _filteredIncome;
  late double _filteredExpenses;
  late double _filteredBalance;
  String _displayCurrency = 'UGX'; // Currency to display all amounts in
  
  // Simple conversion rates (in a real app, these would come from an API)
  final Map<String, Map<String, double>> _conversionRates = {
    'USD': {'USD': 1.0, 'EUR': 0.85, 'UGX': 3700.0},
    'EUR': {'USD': 1.18, 'EUR': 1.0, 'UGX': 4350.0},
    'UGX': {'USD': 0.00027, 'EUR': 0.00023, 'UGX': 1.0},
  };

  @override
  void initState() {
    super.initState();
    _filteredIncome = widget.income;
    _filteredExpenses = widget.expenses;
    _filteredBalance = widget.balance;
    _loadDisplayCurrency();
    _refreshFirestoreData();
  }
  
  // Refresh data from Firestore
  Future<void> _refreshFirestoreData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('Refreshing transactions from Firestore for statistics screen');
        final firestoreTransactions = await TransactionService.loadTransactions(user.email);
        
        if (mounted) {
          setState(() {
            // Update transactions list with Firestore data
            widget.transactions.clear();
            widget.transactions.addAll(firestoreTransactions);
            // Recalculate with new data
            _recalculateFinancials();
          });
        }
      }
    } catch (e) {
      debugPrint('Error refreshing Firestore data: $e');
    }
  }

  Future<void> _loadDisplayCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayCurrency = prefs.getString('selectedCurrency') ?? 'UGX';
    });
    _recalculateFinancials();
  }

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 1200;
    
    final filteredTransactions = _filterTransactions(
      widget.transactions,
      _selectedPeriod,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Currency Selector
          PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _displayCurrency,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 18),
              ],
            ),
            onSelected: (String currency) {
              setState(() {
                _displayCurrency = currency;
              });
              _recalculateFinancials();
            },
            itemBuilder: (BuildContext context) {
              return CurrencyUtils.availableCurrencies.map((String currency) {
                return PopupMenuItem<String>(
                  value: currency,
                  child: Row(
                    children: [
                      Text(currency),
                      const SizedBox(width: 8),
                      Text(
                        '(${CurrencyUtils.getSymbol(currency)})',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          TextButton.icon(
            onPressed: _exportUserData,
            icon: const Icon(Icons.download, color: Colors.blue, size: 20),
            label: const Text(
              'Export',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(isWeb ? 24.0 : 16.0),
        child: isWeb ? _buildWebLayout(filteredTransactions) : _buildMobileLayout(filteredTransactions),
      ),
    );
  }

  // Web layout with side-by-side charts and stats
  Widget _buildWebLayout(List<Transaction> filteredTransactions) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary section
          TransactionSummary(
            balance: _filteredBalance,
            income: _filteredIncome,
            expenses: _filteredExpenses,
            currency: _displayCurrency,
          ),
          const SizedBox(height: 30),
          
          Row(
            children: [
              // Left side - Controls and Chart
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilterControls(),
                    const SizedBox(height: 20),
                    _buildCategoryControls(),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 400,
                      child: _buildBarChart(filteredTransactions),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              
              // Right side - Legend and Sort
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSortControls(),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 400,
                      child: _buildLegend(filteredTransactions),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Mobile layout with vertical stacking
  Widget _buildMobileLayout(List<Transaction> filteredTransactions) {
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Combined Balance, Income, and Expenses Section
          TransactionSummary(
            balance: _filteredBalance,
            income: _filteredIncome,
            expenses: _filteredExpenses,
            currency: _displayCurrency,
          ),
          const SizedBox(height: 20),
          
          _buildFilterControls(),
          const SizedBox(height: 20),
          
          _buildCategoryControls(),
          const SizedBox(height: 20),
          
          SizedBox(
            height: screenHeight * 0.4,
            child: _buildBarChart(filteredTransactions),
          ),
          const SizedBox(height: 20),
          
          _buildSortControls(),
          const SizedBox(height: 20),
          
          _buildLegend(filteredTransactions),
        ],
      ),
    );
  }

  Widget _buildFilterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Filter by:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        DropdownButton<String>(
          value: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
              _recalculateFinancials();
            });
          },
          items: const [
            DropdownMenuItem(value: 'Daily', child: Text('Today')),
            DropdownMenuItem(value: 'Weekly', child: Text('This Week')),
            DropdownMenuItem(value: 'Monthly', child: Text('This Month')),
            DropdownMenuItem(value: 'Yearly', child: Text('This Year')),
          ],
          icon: const Icon(Icons.filter_list, color: Colors.blue),
          style: const TextStyle(color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildCategoryControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Category View:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        DropdownButton<String>(
          value: _categoryView,
          onChanged: (value) {
            setState(() {
              _categoryView = value!;
            });
          },
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'Income', child: Text('Income')),
            DropdownMenuItem(value: 'Expense', child: Text('Expense')),
          ],
          icon: const Icon(Icons.category, color: Colors.blue),
          style: const TextStyle(color: Colors.blue),
        ),
      ],
    );
  }

  Widget _buildSortControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sort by Amount:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _sortAscending = !_sortAscending;
            });
          },
          icon: Icon(
            _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.blue,
          ),
          label: Text(
            _sortAscending ? 'Low to High' : 'High to Low',
            style: const TextStyle(color: Colors.blue),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(List<Transaction> filteredTransactions) {
    return StatisticsLegend(
      filteredTransactions: filteredTransactions,
      categoryView: _categoryView,
      sortAscending: _sortAscending,
      getCategoryColor: _getCategoryColor,
      displayCurrency: _displayCurrency,
      convertCurrency: _convertCurrency,
    );
  }

  // Filter transactions based on selected period
  List<Transaction> _filterTransactions(
    List<Transaction> transactions,
    String period,
  ) {
    final now = DateTime.now();
    return transactions.where((tx) {
      switch (period) {
        case 'Daily':
          return tx.date.year == now.year &&
              tx.date.month == now.month &&
              tx.date.day == now.day;
        case 'Weekly':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          return tx.date.isAfter(startOfWeek) &&
              tx.date.isBefore(now.add(const Duration(days: 1)));
        case 'Monthly':
          return tx.date.year == now.year && tx.date.month == now.month;
        case 'Yearly':
          return tx.date.year == now.year;
        default:
          return true;
      }
    }).toList();
  }

  // Recalculate financials based on filtered transactions
  void _recalculateFinancials() {
    final filteredTransactions = _filterTransactions(
      widget.transactions,
      _selectedPeriod,
    );

    setState(() {
      _filteredIncome = filteredTransactions
          .where((tx) => tx.type == 'Income')
          .fold(0.0, (sum, tx) => sum + _convertCurrency(tx.amount, tx.currency, _displayCurrency));

      _filteredExpenses = filteredTransactions
          .where((tx) => tx.type == 'Expense')
          .fold(0.0, (sum, tx) => sum + _convertCurrency(tx.amount, tx.currency, _displayCurrency));

      _filteredBalance = _filteredIncome - _filteredExpenses;
    });
  }

  // Helper to format currency values
  String formatCurrency(double amount, String currencyCode) {
    return CurrencyUtils.formatAmount(amount, currencyCode);
  }

  // Bar Chart Section
  Widget _buildBarChart(List<Transaction> filteredTransactions) {
    final Map<String, double> categoryTotals = {};
    for (var transaction in filteredTransactions) {
      if (_categoryView == 'All' || transaction.type == _categoryView) {
        final convertedAmount = _convertCurrency(transaction.amount, transaction.currency, _displayCurrency);
        categoryTotals[transaction.category] =
            (categoryTotals[transaction.category] ?? 0) + convertedAmount;
      }
    }

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => _sortAscending ? a.value.compareTo(b.value) : b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return const Center(child: Text('No data for selected period/category'));
    }

    // Fix for bar chart index error - ensure we have at least one entry
    if (sortedEntries.isEmpty) {
      return const Center(child: Text('No transactions in selected period'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: sortedEntries.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // Setting max content width to prevent overflow
            maxContentWidth: 150,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${sortedEntries[groupIndex].key}\n${formatCurrency(rod.toY, _displayCurrency)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 80,
              interval: _calculateYAxisInterval(sortedEntries),
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0) return const Text('0');
                
                // Format large numbers
                if (value >= 1000000) {
                  return Text('${(value / 1000000).toStringAsFixed(1)}M');
                } else if (value >= 1000) {
                  return Text('${(value / 1000).toStringAsFixed(1)}K');
                } else {
                  return Text(value.toInt().toString());
                }
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= sortedEntries.length) return Container();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    sortedEntries[idx].key,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                );
              },
              reservedSize: 60,
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: _calculateYAxisInterval(sortedEntries),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(sortedEntries.length, (i) {
          final entry = sortedEntries[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: _getCategoryColor(entry.key),
                width: 22,
                borderRadius: BorderRadius.circular(6),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: 0,
                  color: Colors.grey[200],
                ),
              ),
            ],
            showingTooltipIndicators: [0],
          );
        }),
      ),
    );
  }

  // Helper method to calculate appropriate Y-axis intervals
  double _calculateYAxisInterval(List<MapEntry<String, double>> entries) {
    if (entries.isEmpty) return 1;
    
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    
    // Calculate appropriate interval based on max value
    if (maxValue >= 10000000) {
      return 2000000; // 2M intervals for very large values
    } else if (maxValue >= 1000000) {
      return 500000; // 500K intervals for millions
    } else if (maxValue >= 100000) {
      return 50000; // 50K intervals for hundreds of thousands
    } else if (maxValue >= 10000) {
      return 5000; // 5K intervals for tens of thousands
    } else if (maxValue >= 1000) {
      return 500; // 500 intervals for thousands
    } else if (maxValue >= 100) {
      return 50; // 50 intervals for hundreds
    } else {
      return 10; // 10 intervals for smaller values
    }
  }

  // Generate Legend Items

  // Get Category Color with better distribution
  Color _getCategoryColor(String category) {
    // Create a more comprehensive color system with better distribution
    final Map<String, Color> categoryColors = {
      // Income categories - greens and blues
      'Salary': const Color(0xFF4CAF50),      // Green
      'Bonuses': const Color(0xFF2196F3),     // Blue  
      'Freelance': const Color(0xFF9C27B0),   // Purple
      'Sales': const Color(0xFF00BCD4),       // Cyan
      'Gifts': const Color(0xFFE91E63),       // Pink
      'Investment': const Color(0xFF3F51B5),  // Indigo
      'Business': const Color(0xFF607D8B),    // Blue Grey
      
      // Expense categories - reds, oranges, and warm colors
      'Rent': const Color(0xFFF44336),        // Red
      'Utilities': const Color(0xFF009688),   // Teal
      'Food': const Color(0xFF8BC34A),        // Light Green
      'Transport': const Color(0xFFFF9800),   // Orange
      'Charity': const Color(0xFFCDDC39),     // Lime
      'Bills': const Color(0xFF673AB7),       // Deep Purple
      'Data': const Color(0xFF03A9F4),        // Light Blue
      'Loan': const Color(0xFFFF5722),        // Deep Orange
      'Fees': const Color(0xFFFFC107),        // Amber
      'Healthcare': const Color(0xFFE91E63),  // Pink (different shade)
      'Entertainment': const Color(0xFF9E9E9E), // Grey
      'Shopping': const Color(0xFFFF6B6B),    // Light Red
      'Education': const Color(0xFF4ECDC4),   // Turquoise
      'Insurance': const Color(0xFF45B7D1),   // Sky Blue
      'Travel': const Color(0xFFFFBE76),      // Peach
      'Maintenance': const Color(0xFF96CEB4), // Mint
      'Subscription': const Color(0xFFFECEA8), // Light Orange
      'Tax': const Color(0xFFDDA0DD),         // Plum
      'Other': const Color(0xFF795548),       // Brown
    };

    // If category exists in map, return its color
    if (categoryColors.containsKey(category)) {
      return categoryColors[category]!;
    }

    // For unknown categories, generate a deterministic color based on hash
    final hash = category.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.8).toColor();
  }

  void _exportUserData() async {
    await ExportUtil.exportTransactions(
      context: context,
      transactions: widget.transactions,
      selectedPeriod: _selectedPeriod,
      filterTransactions: _filterTransactions,
    );
  }
}
