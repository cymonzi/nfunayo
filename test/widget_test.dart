import 'package:flutter_test/flutter_test.dart';
import 'package:nfunayo/screens/start_screen.dart'; // Updated to the correct screen import
import 'package:flutter/material.dart';

void main() {
  testWidgets('App starts correctly', (WidgetTester tester) async {
    // Replaced 'ExpenseTrackerApp' with the correct 'KapayApp' class
    await tester.pumpWidget(
      const MaterialApp(home: StartScreen()),
    ); // Testing StartScreen widget

    // Verify the presence of specific elements on the screen
    expect(find.text('Welcome to Nfunayo!'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
