import 'package:flutter/material.dart';

class BuyScreen extends StatelessWidget {
  const BuyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Buy Content Here',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
