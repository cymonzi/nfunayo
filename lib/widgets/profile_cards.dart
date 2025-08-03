import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/profile_header.dart';

class ProfileCard extends StatelessWidget {
  final String userName;
  final String userEmail;
  final File? customImage;
  final String? avatarUrl;
  final ValueChanged<dynamic> onEditAvatar;

  const ProfileCard({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.customImage,
    required this.onEditAvatar,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ProfileHeader(
          username: userName,
          email: userEmail,
          customImage: customImage,
              avatarUrl: avatarUrl,
          onEditAvatar: onEditAvatar,
        ),
      ),
    );
  }
}

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('About Us', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 10, 10, 10))),
            SizedBox(height: 8),
            Text(
              'Nfunayo is a next-level expense tracker under the SMK MoneyKind company. Our mission is to help you manage your finances with ease and confidence.',
              style: TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
