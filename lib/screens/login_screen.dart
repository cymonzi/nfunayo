import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nfunayo/screens/home_screen.dart'; // Ensure HomeScreen is defined
import 'package:nfunayo/screens/register_screen.dart'; // Import RegisterScreen
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;  // For password visibility toggle

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();  // Form validation key

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;  // Return if form is invalid
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResult = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save user info locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', authResult.user!.uid);

      // Navigate to home screen if authentication is successful
      if (mounted) {
        // Use pushReplacement to remove the current login screen from the stack
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExpenseTrackerHome(userId: authResult.user!.uid),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Display error message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    } catch (e) {
      // Handle other potential errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.blue, // Match the registration screen's style
      ),
      body: Center(
        child: SingleChildScrollView( // Ensures proper scrolling for smaller screens
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,  // Adds shadow for elevated look
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),  // Rounded corners for card
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,  // Form key for validation
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$").hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Loading Indicator or Login Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('Login'),
                          ),
                    const SizedBox(height: 10),

                    // Forgot Password Button
                    TextButton(
                      onPressed: () {
                        // Navigate to a password reset screen (if any)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Forgot password coming soon')),
                        );
                      },
                      child: const Text('Forgot password?', style: TextStyle(color: Color.fromARGB(255, 64, 69, 73))),
                    ),

                    const SizedBox(height: 20),

                    // Navigate to RegisterScreen for new users
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text(
                        'Don\'t have an account? Create one here.',
                        style: TextStyle(color: Colors.blue, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
