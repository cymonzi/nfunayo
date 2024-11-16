import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nfunayo/screens/budgeting_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:logger/logger.dart';
import 'package:fl_chart/fl_chart.dart';
import 'statistics_screen.dart';  
import 'buy_screen.dart';  
import 'earn_screen.dart';


File? _profileImage;
TextEditingController _usernameController = TextEditingController(text: 'NFUNAYO');
  TextEditingController _emailController = TextEditingController(text: 'user@example.com');

class ExpenseTrackerHome extends StatefulWidget {
  const ExpenseTrackerHome({super.key, required String userId});

  @override
  ExpenseTrackerHomeState createState() => ExpenseTrackerHomeState();
}

class ExpenseTrackerHomeState extends State<ExpenseTrackerHome> {
  int _selectedIndex = 0;

// ignore: unused_element
void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
  });

  // Handle navigation based on the selected index
  switch (index) {
    case 0:
      // Navigate to Home Screen
      Navigator.push(context, MaterialPageRoute(builder: (context) =>  const ExpenseTrackerHome(userId: '',)));
      break;
    case 1:
      // Navigate to Statistics Screen
      Navigator.push(context, MaterialPageRoute(builder: (context) => const StatisticsScreen()));
      break;
    case 2:
      // Navigate to Buy Screen
      Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyScreen()));
      break;
    case 3:
      // Navigate to Earn Screen
      Navigator.push(context, MaterialPageRoute(builder: (context) => const EarnScreen()));
      break;
    // case 4:
    //   // Navigate to History Screen
    //   Navigator.push(context, MaterialPageRoute(builder: (context) => _buildTransactionHistory(),
    //   ),);
    //   break;
    default:
      break;
  }
}



  double _balance = 0;
  double _income = 0;
  double _expenses = 0;
  final List<Map<String, dynamic>> _transactions = [];
  final List<String> _categories = ['Food', 'Transport', 'Utilities', 'Shopping', 'Other'];
  // Add TextEditingControllers at the class level for persistent state
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  String _selectedCategory = 'Food';
  String _selectedType = 'Expense';

@override
void dispose() {
  descriptionController.dispose();
  amountController.dispose();
  super.dispose();
}

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = prefs.getString('transactions');
    if (transactionsString != null) {
      final List<Map<String, dynamic>> transactions = List<Map<String, dynamic>>.from(
          json.decode(transactionsString).map((item) => Map<String, dynamic>.from(item))
      );
      setState(() {
        _transactions.addAll(transactions);
        _recalculateIncomeAndExpenses();
      });
    }
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsString = json.encode(_transactions);
    await prefs.setString('transactions', transactionsString);
  }

 Future<void> _confirmClearTransactions() async {
  final shouldClear = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Clear All"),
        content: const Text("Are you sure you want to clear all transactions?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Clear All"),
          ),
        ],
      );
    },
  );

  if (shouldClear == true) {
    await _clearAllTransactions();
  }
}

  Future<void> _clearAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('transactions');
    setState(() {
      _transactions.clear();
      _income = 0;
      _expenses = 0;
      _balance = 0;
    });
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All transactions cleared!")),
    );
  }


  void _showAddTransactionBottomSheet() {
     descriptionController.clear();
  amountController.clear();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allows the BottomSheet to resize with keyboard
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Add space for keyboard
        left: 16.0,
        right: 16.0,
      ),
      child: _buildTransactionForm(),
    ),
  );
}

  Widget _buildTransactionForm({Map<String, dynamic>? transaction}) {
     if (transaction != null) {
    descriptionController.text = transaction['description'] ?? '';
    amountController.text = transaction['amount']?.toString() ?? '';
  }

return Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      _buildTextField(controller: descriptionController, label: 'Description'),
      _buildTextField(controller: amountController, label: 'Amount', keyboardType: TextInputType.number),
      _buildCategoryDropdown(_selectedCategory, (newValue) => setState(() => _selectedCategory = newValue!)),
      _buildTypeRadio(_selectedType, (value) => setState(() => _selectedType = value!)),
      _buildTransactionButton(transaction, descriptionController, amountController, _selectedCategory, _selectedType),
    ],
  ),
);

}


  TextField _buildTextField({required TextEditingController controller, required String label, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: keyboardType,
       autofocus: true,
    );
  }

  DropdownButton<String> _buildCategoryDropdown(String category, void Function(String?) onChanged) {
    return DropdownButton<String>(
      value: category,
      items: _categories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
      onChanged: onChanged,
    );
  }

  Row _buildTypeRadio(String type, void Function(String?) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildRadio('Income', type, onChanged),
        const Text('Income'),
        _buildRadio('Expense', type, onChanged),
        const Text('Expense'),
      ],
    );
  }

  Radio<String> _buildRadio(String value, String groupValue, void Function(String?) onChanged) {
    return Radio<String>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }

  ElevatedButton _buildTransactionButton(Map<String, dynamic>? transaction, TextEditingController descriptionController, TextEditingController amountController, String category, String type) {
    return ElevatedButton(
      onPressed: () {
        if (descriptionController.text.isNotEmpty && amountController.text.isNotEmpty) {
          final amount = double.parse(amountController.text);
          setState(() {
            if (transaction == null) {
              _addTransaction(descriptionController, amount, category, type);
            } else {
              _updateTransaction(transaction, descriptionController, amount, category, type);
            }
            _saveTransactions();
          });
          Navigator.pop(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: 
      Text(
        transaction == null ? 'Add Transaction' : 'Update Transaction',
        style: const TextStyle(color: Colors.white),
        ),
      
      
    );
  }

  void _addTransaction(TextEditingController descriptionController, double amount, String category, String type) {
    _transactions.add({
      'id': _transactions.length + 1,
      'description': descriptionController.text,
      'amount': amount,
      'category': category,
      'type': type,
      'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });
    if (type == 'Income') {
      _income += amount;
    } else {
      _expenses += amount;
    }
    _balance = _income - _expenses;

     descriptionController.clear();
  amountController.clear();
  }

  void _updateTransaction(Map<String, dynamic> transaction, TextEditingController descriptionController, double amount, String category, String type) {
    final index = _transactions.indexOf(transaction);
    _transactions[index] = {
      'id': transaction['id'],
      'description': descriptionController.text,
      'amount': amount,
      'category': category,
      'type': type,
      'date': transaction['date'],
    };
    _recalculateIncomeAndExpenses();
    _balance = _income - _expenses;
  }

  void _recalculateIncomeAndExpenses() {
    _income = _transactions.where((tx) => tx['type'] == 'Income').fold(0.0, (sum, tx) => sum + tx['amount']);
    _expenses = _transactions.where((tx) => tx['type'] == 'Expense').fold(0.0, (sum, tx) => sum + tx['amount']);
  }

// Method to open settings screen
void _openSettings() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const SettingsScreen()),  // Make sure SettingsScreen is defined
  );
}



// Method to save profile changes
void _saveProfileChanges() {
  
  var logger = Logger();

logger.i('Profile changes saved successfully.');
  
  // Here, you would implement saving logic (e.g., updating Firebase, local storage, etc.)
    String updatedUsername = _usernameController.text;
    String updatedEmail = _emailController.text;

    // For demonstration purposes, print the updated values
    // ignore: avoid_print
    print("Updated Username: $updatedUsername");
    // ignore: avoid_print
    print("Updated Email: $updatedEmail");

    // After saving, close the dialog
    Navigator.pop(context);
}
Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

 // Show the profile dialog
  void _showUserProfile() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Profile Details'),
        content: SingleChildScrollView( // Allows the content to scroll if it's too long
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage('assets/images/log.png') as ImageProvider,
                    backgroundColor: Colors.blue[100],
                  ),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.blue),
                    onPressed: _pickImage,  // Trigger the image picker
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                controller: _usernameController,  // Bind to the username controller
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                controller: _emailController,  // Bind to the email controller
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),  // Close the dialog
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: _saveProfileChanges,  // Save profile changes
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Every Penny Count'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _confirmClearTransactions),
          IconButton(icon: const Icon(Icons.account_circle), onPressed: _showUserProfile),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0    ? _buildEnhancedHomeScreen()
    : _selectedIndex == 1
        ? _buildStatisticsScreen()
        : _selectedIndex == 2
            ? _buildBuyScreen()
            : _selectedIndex == 3
                ? _buildEarnScreen()
                : SizedBox.shrink(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),

bottomNavigationBar: BottomNavigationBar(
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home, color: Colors.blue),
      label: 'Home',
      tooltip: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.analytics, color: Colors.blue),
      label: 'Statistics',
      tooltip: 'Statistics',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.shopping_cart, color: Colors.blue),
      label: 'Buy',
      tooltip: 'Buy',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.group_add, color: Colors.blue),
      label: 'Earn',
      tooltip: 'Earn',
    ),
  ],
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() {
      _selectedIndex = index;
    });
  },
  selectedItemColor: Colors.blue, // Keep selected item color as blue
  unselectedItemColor: Colors.black, // Set unselected item color to black
  showUnselectedLabels: true, // Ensure unselected labels are visible
  type: BottomNavigationBarType.fixed, // Keeps all items on the bottom nav bar visible

),

    );
  }


Widget _buildDrawer() {
  return SafeArea(  // Ensures the Drawer does not overlap the status bar
    child: Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),  // Removes the curved border
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildProfileSection(),
                const Divider(),
                _buildSectionHeader('Features'),

                // Drawer items
                _buildDrawerItem(Icons.account_balance_wallet, 'Expenses', () {
                  Navigator.pop(context);
                }),
                _buildDrawerItem(Icons.bar_chart, 'Budgeting Tools', _showBudgetingTools),
                _buildDrawerItem(Icons.savings, 'Save', _showSave),
                _buildDrawerItem(Icons.trending_up, 'Invest', _showInvest),
                const Divider(),
                _buildDrawerItem(Icons.support_agent, 'Help', _showHelp),
                _buildDrawerItem(Icons.settings , 'Settings', _openSettings),
                _buildDrawerItem(Icons.exit_to_app, 'Log Out', _showLogout),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

 Widget _buildProfileSection() {
    return const DrawerHeader(
       decoration: BoxDecoration(color: Colors.blue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/images/log.png'),
          ),
          SizedBox(height: 10),
          Text(
            'NFUNAYO',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHomeScreen() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTransactionSummary(),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSummary() {
    return Card(
      elevation: 4,
      color: Colors.lightBlue[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow(Icons.account_balance_wallet, 'Balance:', 'UGX ${_balance.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            _buildSummaryRow(Icons.arrow_upward, 'Income:', 'UGX ${_income.toStringAsFixed(2)}', color: Colors.green[700]!),
            _buildSummaryRow(Icons.arrow_downward, 'Expenses:', 'UGX ${_expenses.toStringAsFixed(2)}', color: Colors.red[700]!),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, color: color ?? Colors.blue),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value, style: TextStyle(color: color ?? Colors.blue, fontWeight: FontWeight.bold)),
      ],
    );
  }
Widget _buildTransactionList() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Heading
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Text(
          'For This Month',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
             color: Colors.blue
          ),
        ),
      ),
      // Transaction List
      ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          final color = transaction['type'] == 'Income' ? Colors.green : Colors.red;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 2.0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              leading: Icon(
                transaction['type'] == 'Income' ? Icons.arrow_upward : Icons.arrow_downward,
                color: color,
              ),
              title: Text(
                transaction['description'],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${transaction['category']} - ${transaction['date']}',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UGX ${transaction['amount'].toStringAsFixed(2)}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8.0),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Color.fromARGB(255, 51, 48, 48)),
                    onPressed: () {
                      _confirmDeleteTransaction(context, index);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

// Function to confirm the deletion
void _confirmDeleteTransaction(BuildContext context, int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog without deleting
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteTransaction(index); // Delete the transaction
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
}

  // Function to handle editing a transaction (optional)
  // ignore: unused_element
  void _showEditTransaction(Map<String, dynamic> transaction) {
    // Implement editing functionality if needed
  }

// Function to delete a transaction
void _deleteTransaction(int index) {
  setState(() {
    _transactions.removeAt(index); // Remove the transaction at the given index
  });
}




//  Widget _buildTransactionHistory() {
//   return ListView.builder(
//     itemCount: _transactions.length,
//     padding: const EdgeInsets.all(8.0),
//     itemBuilder: (context, index) {
//       final transaction = _transactions[index];
//       final isIncome = transaction['type'] == 'Income';
//       final color = isIncome ? Colors.green : Colors.red;
//       final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

//       return Card(
//         margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
//         elevation: 3.0,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
//         child: ListTile(
//           contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//           leading: CircleAvatar(
//             backgroundColor: color.withOpacity(0.2),
//             child: Icon(icon, color: color),
//           ),
//           title: Text(
//             transaction['description'],
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//           ),
//           subtitle: Text(
//             '${transaction['category']} - ${transaction['date']}',
//             style: const TextStyle(color: Colors.grey, fontSize: 14.0),
//           ),
//           trailing: Text(
//             '${isIncome ? '+' : '-'} UGX ${transaction['amount'].toStringAsFixed(2)}',
//             style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16.0),
//           ),
//           onTap: () => _showEditTransaction(transaction),
//         ),
//       );
//     },
//   );
// }


  Widget _buildDrawerItem(IconData icon, String title, void Function()? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      onTap: onTap,
    );
  }

   Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showBudgetingTools() {
    Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const BudgetingScreen()),
    );
    }

  void _showSave() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Save section coming soon!")));
  }

   void _showInvest() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invest section coming soon!")));
  }


 void _showHelp() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Help & Support"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "If you need assistance, please use the information below to get in touch with our support team:",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blue),
                SizedBox(width: 8),
                Text("Helpline:"),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: Text("+256703283529"),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Text("Email Support:"),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: Text("support@nfunayo.com"),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.message, color: Colors.blue),
                SizedBox(width: 8),
                Text("WhatsApp"),
              ],
            ),
            Padding(
              padding: EdgeInsets.only(left: 32.0),
              child: Text("Whatsapp us on +256703283529"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      );
    },
  );
}


void _showLogout() {
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog

              // Show the SnackBar
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Logout Successful, Please Enter details to login Again")));

              // Navigate to the login screen and replace the current screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()), // Ensure LoginScreen is your actual login widget
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      );
    },
  );
}


  
  _buildBuyScreen() {}
  
  _buildEarnScreen() {}

Widget _buildStatisticsScreen() {
  // Calculate statistics dynamically
  final totalTransactions = _transactions.length;
  final totalIncome = _transactions
      .where((tx) => tx['type'] == 'Income')
      .fold(0.0, (sum, tx) => sum + tx['amount']);
  final totalExpenses = _transactions
      .where((tx) => tx['type'] == 'Expense')
      .fold(0.0, (sum, tx) => sum + tx['amount']);

  // Group expenses by category for the pie chart
  final Map<String, double> categoryBreakdown = {};
  for (var transaction in _transactions) {
    if (transaction['type'] == 'Expense') {
      final category = transaction['category'];
      categoryBreakdown[category] =
          (categoryBreakdown[category] ?? 0) + transaction['amount'];
    }
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Statistics This Week',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 20),

        // Total Transactions
        _buildStatCard('Total Transactions', '$totalTransactions',
            Icons.receipt_long, Colors.blue),

        // Total Expenses
        _buildStatCard('Total Expenses', '\$${totalExpenses.toStringAsFixed(2)}',
            Icons.attach_money, Colors.red),

        // Total Income
        _buildStatCard('Total Income', '\$${totalIncome.toStringAsFixed(2)}',
            Icons.account_balance_wallet, Colors.green),

        // Spending Trend Chart (Line Chart)
        const SizedBox(height: 20),
        const Text(
          'Spending Trend',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 10),
        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: Colors.blue.withOpacity(0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateTrendData(), // Function to create FlSpot list
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Expense Breakdown by Category
        const Text(
          'Expense Breakdown by Category',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sections: categoryBreakdown.entries
                  .map((entry) => PieChartSectionData(
                        color: _getCategoryColor(entry.key),
                        value: entry.value,
                        title: entry.key,
                        radius: 50,
                        titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

// Helper to generate spending trend data for the chart
List<FlSpot> _generateTrendData() {
  // Group transactions by day of the week
  final Map<int, double> weeklySpending = {};
  for (var transaction in _transactions) {
    if (transaction['type'] == 'Expense') {
      final day = DateTime.parse(transaction['date']).weekday;
      weeklySpending[day] =
          (weeklySpending[day] ?? 0) + transaction['amount'];
    }
  }

  // Generate FlSpot list for the line chart
  return List.generate(
      7,
      (index) => FlSpot(index.toDouble(),
          weeklySpending[index + 1]?.toDouble() ?? 0));
}

// Helper to assign colors to categories
Color _getCategoryColor(String category) {
  switch (category) {
    case 'Food':
      return Colors.red;
    case 'Rent':
      return Colors.green;
    case 'Transport':
      return Colors.blue;
    case 'Other':
      return Colors.yellow;
    default:
      return Colors.grey;
  }
}

// Reusable Stat Card Widget
Widget _buildStatCard(String title, String value, IconData icon, Color iconColor) {
  return Card(
    elevation: 5,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 40,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}




  
}
  
