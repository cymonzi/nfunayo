import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated file
import 'screens/start_screen.dart';
import 'screens/home_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/notification_service.dart';
import 'package:webview_flutter/webview_flutter.dart'; // Import WebView package
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'; // For iOS WebView

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set WebView platform for iOS only when on iOS
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    WebViewPlatform.instance = WebKitWebViewPlatform();
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Center(
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Optionally restart the app or navigate to a safe screen
                },
                child: const Text('Restart App'),
              ),
            ],
          ),
        ),
      ),
    );
  };

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final notificationService = NotificationService(
    flutterLocalNotificationsPlugin,
  );

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize notifications
  await notificationService.initialize();

  // Clear unread count on app start
  await notificationService.clearUnreadCount();

  // Schedule daily notifications
  await notificationService.scheduleNotifications();

  runApp(const Nfunayo());
}

class Nfunayo extends StatelessWidget {
  const Nfunayo({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.green),
      textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.black)),
    );

    return MaterialApp(
      title: 'Nfunayo',
      theme: lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const StartScreen(),
        '/home':
            (context) => HomeScreen(
              userName: 'User', // Placeholder
              userEmail: 'user@example.com', // Placeholder
            ),
      },
    );
  }
}
