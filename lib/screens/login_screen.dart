// ignore_for_file: use_build_context_synchronously, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:nfunayo/screens/register_screen.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import '../services/firestore_service.dart';
import '../utils/error_handler.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true; // Add this variable

  @override
  void initState() {
    super.initState();
    _checkUserSession();
  }

  final AuthService _authService = AuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        debugPrint('=== LOGIN ATTEMPT ===');
        debugPrint('Email: ${_emailController.text.trim()}');
        debugPrint('Password length: ${_passwordController.text.trim().length}');
        
        final user = await _authService.signIn(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        debugPrint('Login successful for user: ${user?.email}');
        debugPrint('User UID: ${user?.uid}');

        // Clear existing SharedPreferences data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Fetch user profile from Firestore
        final firestoreService = FirestoreService();
        final userProfile = await firestoreService.getUserProfile(user!.uid);
        debugPrint('User Profile from Firestore: $userProfile');

        // Check if user profile exists in Firestore
        if (userProfile.isEmpty) {
          debugPrint('WARNING: User profile not found in Firestore, creating one...');
          // Create profile for existing Firebase Auth user
          final email = user.email ?? '';
          final username = email.contains('@') ? email.split('@')[0] : 'User';
          
          await firestoreService.saveUserProfile(
            uid: user.uid,
            name: username,
            email: email,
            avatar: 'avatarx.json',
          );
          
          final newProfile = await firestoreService.getUserProfile(user.uid);
          debugPrint('Created new profile: $newProfile');
        }

        // Save new user profile locally
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userName', userProfile['name'] ?? '');
        await prefs.setString('userEmail', userProfile['email'] ?? '');
        debugPrint('Saved UserName: ${prefs.getString('userName')}');
        debugPrint('Saved UserEmail: ${prefs.getString('userEmail')}');

        if (!mounted) return;

        ErrorHandler.showSuccessSnackBar(
          context,
          'Welcome back! Login successful.'
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userName: userProfile['name'] ?? 'User',
              userEmail: userProfile['email'] ?? user.email ?? '',
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        setState(() => _isLoading = false);
        debugPrint('=== LOGIN FIREBASE AUTH ERROR ===');
        debugPrint('Error code: ${e.code}');
        debugPrint('Error message: ${e.message}');
        ErrorHandler.showErrorSnackBar(
          context,
          ErrorHandler.getAuthErrorMessage(e)
        );
      } catch (e) {
        setState(() => _isLoading = false);
        debugPrint('=== LOGIN GENERAL ERROR ===');
        debugPrint('Error: $e');
        ErrorHandler.showErrorSnackBar(
          context,
          'Login failed. Please check your internet connection and try again.'
        );
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.signInWithGoogle();

      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        ErrorHandler.showErrorSnackBar(
          context,
          'Google Sign-In failed. Please try again.'
        );
        return;
      }

      // Clear existing SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Save user info to Firestore only if it doesn't exist
      final firestoreService = FirestoreService();
      final profile = await firestoreService.getUserProfile(user.uid);
      if (profile.isEmpty) {
        await firestoreService.saveUserProfile(
          uid: user.uid,
          name: user.displayName ?? (user.email?.split('@')[0] ?? ''),
          email: user.email ?? '',
          avatar: user.photoURL ?? 'avatarx.json',
        );
      }

      // Fetch user profile from Firestore
      final userProfile = await firestoreService.getUserProfile(user.uid);

      // Save new user details in SharedPreferences
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', userProfile['name'] ?? '');
      await prefs.setString('userEmail', userProfile['email'] ?? '');
      await prefs.setString('userAvatar', userProfile['avatar'] ?? 'avatarx.json');

      debugPrint('Saved UserName: ${prefs.getString('userName')}');
      debugPrint('Saved UserEmail: ${prefs.getString('userEmail')}');

      final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

      if (!mounted) return;

      if (!seenOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingWrapper()),
        );
      } else {
        _navigateToHomeScreen(
          userProfile['name'] ?? 'User',
          userProfile['email'] ?? '',
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Google Sign-In failed: ${e.toString()}'
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToHomeScreen(String userName, String userEmail) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => HomeScreen(userName: userName, userEmail: userEmail),
      ),
    );
  }

  void _checkUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final userName = prefs.getString('userName') ?? 'User';
      final userEmail = prefs.getString('userEmail') ?? 'user@example.com';
      debugPrint('Fetched UserName: $userName');
      debugPrint('Fetched UserEmail: $userEmail');
      _navigateToHomeScreen(userName, userEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: const _LoginAppBar(),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Semantics(
                      label: 'App logo',
                      child: Image.asset(
                        'assets/images/log.png',
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Header(),
                            const SizedBox(height: 20),
                            _LoginForm(
                              formKey: _formKey,
                              passwordController: _passwordController,
                              emailController: _emailController,
                              obscurePassword: _obscurePassword,
                              togglePasswordVisibility: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            _LoginButton(onPressed: _login),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: _signInWithGoogle,
                              icon: Image.asset(
                                'assets/images/google_logo.png',
                                height: 24,
                                width: 24,
                              ),
                              label: const Text('Sign in with Google'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _FooterActions(emailController: _emailController),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withAlpha(128), // Replaced withOpacity
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}

class _LoginAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LoginAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Login'), backgroundColor: Colors.blue);
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Enter Password to Login',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController passwordController;
  final TextEditingController emailController;
  final bool obscurePassword;
  final VoidCallback togglePasswordVisibility;

  const _LoginForm({
    required this.formKey,
    required this.passwordController,
    required this.emailController,
    required this.obscurePassword,
    required this.togglePasswordVisibility,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: passwordController,
            obscureText: obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.blue, width: 2.0),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: togglePasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters long';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _LoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
      child: const Text('Log in'),
    );
  }
}

class _FooterActions extends StatelessWidget {
  final TextEditingController emailController;

  const _FooterActions({required this.emailController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () async {
            final email = emailController.text.trim();
            if (email.isEmpty ||
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
              ErrorHandler.showWarningSnackBar(
                context,
                'Enter a valid email to reset password.'
              );
              return;
            }

            try {
              await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
              // ignore: use_build_context_synchronously
              ErrorHandler.showSuccessSnackBar(
                context,
                'Password reset email sent.'
              );
            } catch (e) {
              // ignore: use_build_context_synchronously
              ErrorHandler.showErrorSnackBar(
                context,
                'Error: ${e.toString()}'
              );
            }
          },
          child: const Text(
            'Forgot Password?',
            style: TextStyle(color: Colors.blue),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Don\'t have an account?'),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text('Register'),
            ),
          ],
        ),
      ],
    );
  }
}

Future<void> logout(BuildContext context) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Save transactions and settings before clearing user data
    final transactionsString = prefs.getString('transactions');
    final selectedCurrency = prefs.getString('selectedCurrency') ?? 'UGX';
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    
    // Clear only user session data, not transactions
    await prefs.remove('isLoggedIn');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userAvatar');
    await prefs.remove('userId');
    await prefs.remove('avatarUrl');
    await prefs.remove('customImagePath');
    
    // Restore non-user-specific data
    if (transactionsString != null) {
      await prefs.setString('transactions', transactionsString);
    }
    await prefs.setString('selectedCurrency', selectedCurrency);
    await prefs.setBool('notificationsEnabled', notificationsEnabled);
    await prefs.setString('selectedLanguage', selectedLanguage);

    debugPrint('=== LOGOUT (from login_screen) ===');
    debugPrint('Preserved transactions and settings');
    debugPrint('Cleared user session data only');

    // Sign out from Firebase
    final authService = AuthService();
    await authService.signOut();

    // Navigate to the login screen
    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  } catch (e) {
    debugPrint("Logout failed: $e");
    // ignore: use_build_context_synchronously
    ErrorHandler.showErrorSnackBar(
      context,
      'Logout failed. Please try again.'
    );
  }
}
