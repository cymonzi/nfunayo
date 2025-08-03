import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:lottie/lottie.dart';
import 'home_screen.dart';

class OnboardingWrapper extends StatefulWidget {
  final bool fromDrawer;

  const OnboardingWrapper({super.key, this.fromDrawer = false});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  bool _isNavigating = false;

  Future<void> _handleOnDone() async {
    if (_isNavigating) return;

    setState(() => _isNavigating = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('seenOnboarding', true);

      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? user?.email ?? 'User';
      final userEmail = user?.email ?? 'user@example.com'; // Retrieve the email

      if (widget.fromDrawer) {
        Navigator.of(context).pop();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => HomeScreen(
                  userName: userName,
                  userEmail: userEmail, // Pass the email to HomeScreen
                ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving onboarding state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? user?.email ?? 'User';

    return OnboardingScreen(
      onDone: _handleOnDone,
      userName: userName, // Pass userName to OnboardingScreen
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  final VoidCallback onDone;
  final String userName; // Add userName parameter

  const OnboardingScreen({
    super.key,
    required this.onDone,
    required this.userName,
  });

  PageViewModel _buildPage(
    BuildContext context, {
    required List<Map<String, dynamic>> cards,
    double imageFactor = 0.3,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PageViewModel(
      title: "",
      bodyWidget: Center(
        child: SizedBox(
          width: screenWidth * 0.9, // Limit the width of the card
          height: screenHeight * 0.75, // Limit height to allow scrolling
          child: SingleChildScrollView(
            child: Column(
              children:
                  cards.map((card) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        color: const Color(0xFFF7FAFC), // Light card background
                        elevation: 3, // Softer shadow
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Title
                              Text(
                                card['title'],
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black, // Black text for title
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Image or Lottie Animation
                              SizedBox(
                                height: screenHeight * imageFactor,
                                child:
                                    card['isLottie'] == true
                                        ? Lottie.asset(
                                          card['imagePath'],
                                          fit: BoxFit.contain,
                                        )
                                        : Image.asset(
                                          card['imagePath'],
                                          fit: BoxFit.contain,
                                        ),
                              ),
                              const SizedBox(height: 20),

                              // Body
                              Text(
                                card['body'],
                                textAlign: TextAlign.center,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Colors.black, // Black text for body
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ),
      decoration: const PageDecoration(
        imagePadding: EdgeInsets.only(top: 30),
        contentMargin: EdgeInsets.symmetric(horizontal: 20),
        pageColor: Color(0xFFE3F2FD), // Pale blue background
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: IntroductionScreen(
              globalBackgroundColor: const Color(
                0xFFE3F2FD,
              ), // Match page background
              globalHeader: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "User Guide",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800], // Darker blue for header
                  ),
                ),
              ),
              pages: [
                // First Slide: One Card
                _buildPage(
                  context,
                  cards: [
                    {
                      'title':
                          "Welcome to Nfunayo, $userName", // Include userName in the title
                      'body':
                          "Your personal expense tracker by SMK Moneykind.\nMake. Every. Penny. Count.",
                      'imagePath': 'assets/images/log.png',
                      'isLottie': false,
                    },
                  ],
                  imageFactor: 0.25,
                ),

                // Second Slide: Three Cards
                _buildPage(
                  context,
                  cards: [
                    {
                      'title': "Track Your Finances",
                      'body':
                          "View your total balance, income, and expenses from the Home screen.",
                      'imagePath': 'assets/animations/dashboard.json',
                      'isLottie': true,
                    },
                    {
                      'title': "Add Transactions Easily",
                      'body':
                          "Use the '+' button to add an income or expense with full details.",
                      'imagePath': 'assets/animations/add.json',
                      'isLottie': true,
                    },
                    {
                      'title': "Understand Your Spending",
                      'body':
                          "Check your statistics to discover saving patterns and spending trends.",
                      'imagePath': 'assets/animations/piechart.json',
                      'isLottie': true,
                    },
                  ],
                  imageFactor: 0.35,
                ),

                // Third Slide: Two Cards
                _buildPage(
                  context,
                  cards: [
                    {
                      'title': "Access More & Get Help",
                      'body':
                          "Use the menu to access help, provide feedback, or explore the latest updates and resources through the More section.",
                      'imagePath': 'assets/animations/menu.json',
                      'isLottie': true,
                    },
                    {
                      'title': "Manage Your Profile",
                      'body':
                          "Update your personal details or reset your password from the profile screen.",
                      'imagePath': 'assets/animations/profile.json',
                      'isLottie': true,
                    },
                  ],
                  imageFactor: 0.3,
                ),

                // Final Slide: One Card
                _buildPage(
                  context,
                  cards: [
                    {
                      'title': "You're Ready!",
                      'body':
                          "You're all set to start tracking your finances with Nfunayo!",
                      'imagePath': 'assets/animations/success.json',
                      'isLottie': true,
                    },
                  ],
                  imageFactor: 0.3,
                ),
              ],
              onDone: onDone,
              showSkipButton: true,
              skip: const Text("Skip"),
              next: const Icon(Icons.arrow_forward),
              done: const Text(
                "Get Started",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              dotsDecorator: const DotsDecorator(
                activeSize: Size(20.0, 10.0),
                activeColor: Colors.blue,
                size: Size(10.0, 10.0),
                color: Colors.grey,
                activeShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ),
              onChange: (index) => debugPrint('Onboarding page index: $index'),
              curve: Curves.easeInOut,
              animationDuration: 300,
            ),
          ),
        );
      },
    );
  }
}
