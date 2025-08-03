import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_details.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const SettingsScreen({super.key, required this.userName, required this.userEmail});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File? _customImage; // Store the selected image (mobile)
  String? _avatarUrl; // Store the avatar download URL
  bool _isLoading = false;
  // Preferences state - only currency now
  String _selectedCurrency = 'USD';
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Remove phone number loading as we're removing that field
      final customImagePath = prefs.getString('customImagePath');
      if (customImagePath != null) {
        _customImage = File(customImagePath);
      }
      // Load avatar URL if exists
      _avatarUrl = prefs.getString('avatarUrl');
      _nameController.text = prefs.getString('username') ?? widget.userName;
      // Load user preferences - only currency now
      _selectedCurrency = prefs.getString('selectedCurrency') ?? 'USD';
      _isLoading = false;
    });
  }

  void _pickImage(dynamic value) {
    // For web/mobile compatibility, we'll handle Firebase Storage upload
    try {
      if (widget.userEmail.isNotEmpty) {
        // For now, we'll just show a message that image upload is not implemented
        _showMessage('Image upload feature will be implemented soon.');
        return;
      }
    } catch (e) {
      debugPrint('Error with image upload: $e');
      _showMessage('Failed to upload image. Please try again.');
    }
  }

  Future<void> _editProfile() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              // Removed phone number field
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _nameController.text.trim();

                if (newName.isEmpty) {
                  _showMessage('Name cannot be empty');
                  return;
                }

                // Save to SharedPreferences first
                await prefs.setString('username', newName);

                // Update Firestore profile if user is authenticated
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .update({'name': newName});
                    debugPrint('Updated user profile in Firestore');
                  }
                } catch (e) {
                  debugPrint('Error updating Firestore profile: $e');
                }

                // Update local state
                setState(() {
                  _nameController.text = newName;
                });

                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                _showMessage('Profile updated successfully! Changes will reflect across the app.');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error in edit profile: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  ProfileCard(
                    userName: widget.userName,
                    userEmail: widget.userEmail,
                    customImage: _customImage,
                    avatarUrl: _avatarUrl,
                    onEditAvatar: _pickImage,
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ProfileDetails(
                        onEditProfile: _editProfile,
                        onResetPassword: () {
                          _showMessage('Reset password functionality not implemented.');
                        },
                      ),
                    ),
                  ),
                  // PreferencesCard for currency only
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              prefixIcon: const Icon(Icons.monetization_on),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            value: _selectedCurrency,
                            items: const ['USD', 'EUR', 'UGX'].map((item) {
                              return DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              if (value != null) {
                                setState(() => _selectedCurrency = value);
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setString('selectedCurrency', value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  // About Us Card at the bottom
                  const AboutCard(),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
