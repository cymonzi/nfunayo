// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_screen.dart';
import '../utils/error_handler.dart';

class AppDrawer extends StatelessWidget {
  final String userName;
  final String userEmail;
  final bool notificationsEnabled;
  final Function(bool) onNotificationsToggle;
  final VoidCallback onLogout;
  final VoidCallback? onSettingsChanged;

  const AppDrawer({
    required this.userName,
    required this.userEmail,
    required this.notificationsEnabled,
    required this.onNotificationsToggle,
    required this.onLogout,
    this.onSettingsChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Uri feedbackFormUrl = Uri.parse('https://forms.gle/m1oVA9jbVbokVtpSA');
    final Uri helpUrl = Uri.parse('https://smk-moneykind-site.vercel.app/');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade700, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              color: Colors.blue.shade50,
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade100,
                  child: Lottie.asset(
                    'assets/animations/avatarx.json',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Color(0xFF1565C0), // Deep blue
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Settings',
                      style: TextStyle(color: Color(0xFF1976D2), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                subtitle: Text(
                  userEmail,
                  style: const TextStyle(color: Color(0xFF5C6BC0), fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(userName: userName, userEmail: userEmail),
                    ),
                  );
                  // Call the callback when returning from settings
                  if (onSettingsChanged != null) {
                    onSettingsChanged!();
                  }
                },
              ),
            ),
            const Divider(color: Colors.white54, thickness: 1, height: 24),
            ...[ 
              _DrawerItem(
                icon: Icons.help_outline,
                label: 'Help',
                onTap: () async {
                  Navigator.pop(context);
                  if (await canLaunchUrl(helpUrl)) {
                    await launchUrl(helpUrl, mode: LaunchMode.externalApplication);
                  } else {
                    ErrorHandler.showErrorSnackBar(
                      context,
                      'Could not open help site'
                    );
                  }
                },
                color: Color(0xFF1976D2),
              ),
              _DrawerItem(
                icon: Icons.feedback,
                label: 'Feedback',
                onTap: () async {
                  Navigator.pop(context);
                  if (await canLaunchUrl(feedbackFormUrl)) {
                    await launchUrl(feedbackFormUrl, mode: LaunchMode.externalApplication);
                  } else {
                    ErrorHandler.showErrorSnackBar(
                      context,
                      'Could not open feedback form'
                    );
                  }
                },
                color: Color(0xFF1976D2),
              ),
              _DrawerItem(
                icon: Icons.book,
                label: 'User Guide',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const OnboardingWrapper(fromDrawer: true),
                    ),
                  );
                },
                color: Color(0xFF1976D2),
              ),
              _DrawerItem(
                icon: Icons.logout,
                label: 'Logout',
                color: Colors.redAccent,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel', style: TextStyle(color: Colors.green)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onLogout();
                            },
                            child: const Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ].map((item) => Card(
              color: Colors.blue.shade50,
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: item,
            )),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}
