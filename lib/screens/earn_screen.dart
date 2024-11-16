import 'package:flutter/material.dart';

class EarnScreen extends StatelessWidget {
  const EarnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earn'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Earn Content Here',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
