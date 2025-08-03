import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(FirebaseTestApp());
}

class FirebaseTestApp extends StatelessWidget {
  const FirebaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Test',
      home: FirebaseTestScreen(),
    );
  }
}

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String _status = 'Testing Firebase connection...';

  @override
  void initState() {
    super.initState();
    _testFirebaseConnection();
  }

  Future<void> _testFirebaseConnection() async {
    try {
      // Test Firebase Auth
      final auth = FirebaseAuth.instance;
      
      // Test Firestore
      final firestore = FirebaseFirestore.instance;
      
      // Try to read a collection (should fail if not authenticated)
      try {
        final result = await firestore.collection('expense_groups').limit(1).get();
        setState(() {
          _status = 'Firebase connected successfully!\nAuth: Connected\nFirestore: Connected (${result.docs.length} docs in expense_groups)';
        });
      } catch (e) {
        setState(() {
          _status = 'Firebase Auth connected, but Firestore query failed: $e';
        });
      }
      
      // Check current user
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        setState(() {
          _status += '\nCurrent user: ${currentUser.email}';
        });
      } else {
        setState(() {
          _status += '\nNo current user';
        });
      }
      
    } catch (e) {
      setState(() {
        _status = 'Firebase connection failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Test')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            _status,
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
