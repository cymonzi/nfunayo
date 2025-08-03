// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import 'onboarding_screen.dart';
import '../services/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _obscurePassword = true;

  final AuthService _authService = AuthService();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedTerms) {
      ErrorHandler.showWarningSnackBar(
        context, 
        'Please accept the Terms & Conditions to continue.'
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(
          context,
          'Registration failed. Please try again with different credentials.'
        );
        return;
      }

      // Get username from form field or derive from email
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim().isNotEmpty 
          ? _usernameController.text.trim()
          : (email.contains('@') ? email.split('@')[0] : email);

      // Use avatarx.json Lottie file as default avatar for non-Google sign-ups
      final pickedAvatar = 'avatarx.json';

      // Save user profile to Firestore
      final firestoreService = FirestoreService();
      await firestoreService.saveUserProfile(
        uid: user.uid,
        name: username,
        email: email,
        avatar: pickedAvatar,
      );

      // Save user profile locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', username);
      await prefs.setString('userEmail', email);
      await prefs.setString('userAvatar', pickedAvatar);
      await prefs.setString('userId', user.uid);

      setState(() => _isLoading = false);

      ErrorHandler.showSuccessSnackBar(
        context,
        'Account created successfully! Welcome to Nfunayo.'
      );

      // Navigate to onboarding screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingWrapper()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getAuthErrorMessage(e)
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ErrorHandler.showErrorSnackBar(
        context,
        ErrorHandler.getGeneralErrorMessage(e)
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.signInWithGoogle();
      if (user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ErrorHandler.showErrorSnackBar(
            context,
            'Google Sign-In failed. Please try again.'
          );
        }
        return;
      }

      // Save Google profile image if available, else use avatarx.json
      final avatarUrl = user.photoURL ?? 'avatarx.json';
      final username = user.displayName ?? (user.email?.split('@')[0] ?? '');
      final email = user.email ?? '';

      // Save user profile to Firestore only if it doesn't exist
      final firestoreService = FirestoreService();
      final profile = await firestoreService.getUserProfile(user.uid);
      if (profile.isEmpty) {
        await firestoreService.saveUserProfile(
          uid: user.uid,
          name: username,
          email: email,
          avatar: avatarUrl,
        );
      }

      // Save user profile locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userName', username);
      await prefs.setString('userEmail', email);
      await prefs.setString('userAvatar', avatarUrl);

      if (!mounted) return;

      // Navigate to the OnboardingScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingWrapper(fromDrawer: false),
        ),
      );
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          'Google Sign-In failed: ${e.toString()}'
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05,
          ),
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
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          'Username',
                          _usernameController,
                          'Please enter your username',
                          icon: Icons.person,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          'Email',
                          _emailController,
                          'Please enter a valid email address',
                          isEmail: true,
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 10),
                        _buildTextField(
                          'Password',
                          _passwordController,
                          'Please enter your password',
                          obscureText: _obscurePassword,
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptedTerms = value!;
                                });
                              },
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Terms & Conditions'),
                                      content: const SingleChildScrollView(
                                        child: Text(
                                          'By registering, you agree to our Terms & Conditions and Privacy Policy.',
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: const Text(
                                  'I accept the Terms & Conditions',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                onPressed: _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(
                                    double.infinity,
                                    screenHeight * 0.06,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                ),
                                child: const Text('Register'),
                              ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Already have an account?'),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Login here',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _signInWithGoogle,
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
                            side: const BorderSide(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String validationMessage, {
    bool obscureText = false,
    bool isEmail = false,
    bool isPassword = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return validationMessage;
        }
        if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        if (isPassword && value.length < 6) {
          return 'Password must be at least 6 characters long';
        }
        return null;
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
