import 'package:flutter/material.dart';

class BudgetingScreen extends StatelessWidget {
  const BudgetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgeting'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Budgeting Page Content Here',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
