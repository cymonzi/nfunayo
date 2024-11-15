import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:logger/logger.dart';

File? _profileImage;

class ExpenseTrackerHome extends StatefulWidget {
  const ExpenseTrackerHome({super.key});

  @override
  ExpenseTrackerHomeState createState() => ExpenseTrackerHomeState();
}

class ExpenseTrackerHomeState extends State<ExpenseTrackerHome> {
  int _selectedIndex = 0;
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
  
  // Close the dialog after saving
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

void _showUserProfile() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: const Text('Profile Details'),
      content: Column(
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
                onPressed: _pickImage,
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: 'NFUNAYO'),  // Add controller for real data
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: 'user@example.com'), // Add controller for real data
          ),
          const SizedBox(height: 10),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     ElevatedButton.icon(
          //       icon: const Icon(Icons.logout),
          //       label: const Text('Logout'),
          //       onPressed: _showLogout,  // Define logout function
          //     ),
          //     ElevatedButton.icon(
          //       icon: const Icon(Icons.settings),
          //       label: const Text('Settings'),
          //       onPressed: _openSettings,  // Define openSettings function
          //     ),
          //   ],
          // ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _saveProfileChanges,  // Define saveProfileChanges function
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
        title: const Text('Transactions'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _confirmClearTransactions),
          IconButton(icon: const Icon(Icons.account_circle), onPressed: _showUserProfile),
        ],
      ),
      drawer: _buildDrawer(),
      body: _selectedIndex == 0 ? _buildEnhancedHomeScreen() : _buildTransactionHistory(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.blue), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics, color: Colors.blue), label: 'Statistics'),
          BottomNavigationBarItem (icon: Icon(Icons.shopping_cart, color: Colors.blue),
      label: 'Buy'),
          BottomNavigationBarItem(icon: Icon(Icons.group_add, color: Colors.blue), label: 'Earn'),  
          BottomNavigationBarItem(icon: Icon(Icons.history, color: Colors.blue), label: 'History'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: _onItemTapped,
      ),
    );
  }

Widget _buildDrawer() {
  return Drawer(
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
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        final color = transaction['type'] == 'Income' ? Colors.green : Colors.red;

        return ListTile(
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
          trailing: Text(
            'UGX ${transaction['amount'].toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _buildTransactionHistory() {
     return ListView.builder(
    itemCount: _transactions.length,
    itemBuilder: (context, index) {
      final transaction = _transactions[index];
      return ListTile(
        title: Text(transaction['description']),
        subtitle: Text('${transaction['category']} - ${transaction['date']}'),
        trailing: Text('${transaction['type'] == 'Income' ? '+' : '-'} UGX ${transaction['amount'].toStringAsFixed(2)}'),
        onTap: () => _showEditTransaction(transaction),
      );
    },
  );


  }

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
   Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Budegeting Tools section coming soon!")));
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

  _showEditTransaction(Map<String, dynamic> transaction) {}
}
  
