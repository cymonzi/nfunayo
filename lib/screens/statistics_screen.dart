import 'package:flutter/material.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Statistics Content Here',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
