import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:nfunayo/screens/start_screen.dart';
import 'firebase_options.dart'; // Ensure this is generated and correctly imported

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with options (this uses the generated Firebase options for your platform)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Uses the generated Firebase options for your platform (Android, iOS, Web)
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner in release builds
      title: 'Nfunayo Expense Tracker', // Title for your app
      theme: ThemeData(
        primarySwatch: Colors.blue, // Theme color (can be customized)
      ),
      home: const StartScreen(), // Home screen of your app
    );
  }
}
