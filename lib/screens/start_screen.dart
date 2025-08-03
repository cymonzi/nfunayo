import 'package:flutter/material.dart';
import 'package:nfunayo/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nfunayo/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  StartScreenState createState() => StartScreenState();
}

class StartScreenState extends State<StartScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  void _checkUserSession() async {
    try {
      // Check Firebase Auth state first
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is authenticated, fetch latest profile from Firestore
        final firestoreService = FirestoreService();
        
        try {
          final userProfile = await firestoreService.getUserProfile(user.uid);
          
          // Update SharedPreferences with latest data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userName', userProfile['name'] ?? user.displayName ?? 'User');
          await prefs.setString('userEmail', user.email ?? '');
          await prefs.setString('userAvatar', userProfile['avatar'] ?? 'avatar1.png');
          await prefs.setString('userId', user.uid);
          
          final userName = userProfile['name'] ?? user.displayName ?? 'User';
          
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userName: userName, userEmail: user.email ?? ''),
            ),
          );
        } catch (e) {
          // If Firestore fetch fails, fall back to local data
          debugPrint('Failed to fetch user profile from Firestore: $e');
          
          final prefs = await SharedPreferences.getInstance();
          final userName = prefs.getString('userName') ?? user.displayName ?? 'User';
          
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => HomeScreen(userName: userName, userEmail: user.email ?? ''),
            ),
          );
        }
      } else {
        // No authenticated user, check local storage for backup
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        
        if (isLoggedIn) {
          // Clear stale local data if Firebase auth is null
          await prefs.clear();
        }
        
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking user session: $e');
      // Fallback to login screen on any error
      Navigator.pushReplacement(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Check user session after the splash screen delay
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _checkUserSession();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Set background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo with scaling effect
            ScaleTransition(
              scale: _animation,
              child: Image.asset(
                'assets/images/log.png', // Path to logo image
                width: 250, // Adjusted size
                height: 250,
              ),
            ),
            const SizedBox(height: 40),
            // Loading indicator with a message
            const Column(
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 20),
                Text(
                  'NFUNAYO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
