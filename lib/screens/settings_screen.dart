import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Settings Page Content Here',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
