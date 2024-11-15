import 'package:flutter/material.dart';
import 'screens/start_screen.dart';

void main() {
  runApp(const Nfunayo());
}

class Nfunayo extends StatelessWidget {
  const Nfunayo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nfunayo',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const StartScreen(),
    );
  }
}
