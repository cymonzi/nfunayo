// import 'package:flutter/material.dart';

// class HistoryScreen extends StatelessWidget {
//   final List<Map<String, dynamic>> transactions;  // Declare the transactions list

//   // Constructor to accept the transactions list
//   const HistoryScreen({super.key, required this.transactions});

//   // Function to build the transaction history list
//   Widget _buildTransactionHistory() {
//     return ListView.builder(
//       itemCount: transactions.length,
//       padding: const EdgeInsets.all(8.0),
//       itemBuilder: (context, index) {
//         final transaction = transactions[index];
//         final isIncome = transaction['type'] == 'Income';
//         final color = isIncome ? Colors.green : Colors.red;
//         final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

//         return Card(
//           margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
//           elevation: 3.0,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
//           child: ListTile(
//             contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//             leading: CircleAvatar(
//               backgroundColor: color.withOpacity(0.2),
//               child: Icon(icon, color: color),
//             ),
//             title: Text(
//               transaction['description'],
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//             ),
//             subtitle: Text(
//               '${transaction['category']} - ${transaction['date']}',
//               style: const TextStyle(color: Colors.grey, fontSize: 14.0),
//             ),
//             trailing: Text(
//               '${isIncome ? '+' : '-'} UGX ${transaction['amount'].toStringAsFixed(2)}',
//               style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16.0),
//             ),
//             onTap: () => _showEditTransaction(transaction), // Add your method for editing transactions
//           ),
//         );
//       },
//     );
//   }

//   // Method to show edit transaction (if needed)
//   void _showEditTransaction(Map<String, dynamic> transaction) {
//     // Implement the edit functionality here if required
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Transaction History'),
//         backgroundColor: Colors.blue,
//       ),
//       body: _buildTransactionHistory(), // Call the function that builds the transaction list
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(icon: Icon(Icons.home, color: Colors.blue), label: 'Home'),
//           BottomNavigationBarItem(icon: Icon(Icons.analytics, color: Colors.blue), label: 'Statistics'),
//           BottomNavigationBarItem(icon: Icon(Icons.shopping_cart, color: Colors.blue), label: 'Buy'),
//           BottomNavigationBarItem(icon: Icon(Icons.group_add, color: Colors.blue), label: 'Earn'),
//           BottomNavigationBarItem(icon: Icon(Icons.history, color: Colors.blue), label: 'History'),
//         ],
//         currentIndex: 4, // Default to 'History' screen
//         selectedItemColor: Colors.blue[800],
//         onTap: (index) {
//           // Add navigation logic for other screens here
//         },
//       ),
//     );
//   }
// }
