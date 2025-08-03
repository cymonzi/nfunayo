import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_details.dart';
import '../widgets/preferences_card.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const SettingsScreen({super.key, required this.userName, required this.userEmail});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _phoneNumber = '';
  File? _customImage; // Store the selected image (mobile)
  String? _avatarUrl; // Store the avatar download URL
  bool _isLoading = false;
  // Preferences state
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'USD';
  String _selectedLanguage = 'English';
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
      _phoneNumber = prefs.getString('phoneNumber') ?? 'Phone not set';
      final customImagePath = prefs.getString('customImagePath');
      if (customImagePath != null) {
        _customImage = File(customImagePath);
      }
      // Load avatar URL if exists
      _avatarUrl = prefs.getString('avatarUrl');
      _nameController.text = prefs.getString('username') ?? widget.userName;
// Load user points
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedCurrency = prefs.getString('selectedCurrency') ?? 'USD';
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      _isLoading = false;
    });
  }

  void _pickImage(dynamic imageData) async {
    if (imageData != null) {
      try {
        final storageRef = FirebaseStorage.instance.ref().child('avatars/${widget.userEmail}.jpg');
        if (imageData is File) {
          // Limit file size to 1MB
          final fileSize = await imageData.length();
          if (fileSize > 1024 * 1024) {
            _showMessage('Image size must be less than 1MB.');
            return;
          }
          // Save locally
          final appDir = await getApplicationDocumentsDirectory();
          final destPath = '${appDir.path}/profile.jpg';
          final destFile = File(destPath);
          if (await destFile.exists()) {
            await destFile.delete();
          }
          final savedImage = await imageData.copy(destPath);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('customImagePath', savedImage.path);
          setState(() {
            _customImage = savedImage;
          });
          // Upload to Firebase Storage
          await storageRef.putFile(savedImage);
          final url = await storageRef.getDownloadURL();
          setState(() {
            _avatarUrl = url;
          });
          await prefs.setString('avatarUrl', url);
        } else if (imageData is Uint8List) {
          // Limit bytes size to 1MB
          if (imageData.length > 1024 * 1024) {
            _showMessage('Image size must be less than 1MB.');
            return;
          }
          // Web: upload bytes to Firebase Storage
          await storageRef.putData(imageData);
          final url = await storageRef.getDownloadURL();
          setState(() {
            _avatarUrl = url;
          });
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('avatarUrl', url);
          _showMessage('Image uploaded successfully!');
        } else {
          _showMessage('Unsupported image type.');
        }
      } catch (e) {
        debugPrint('Error saving/uploading image: $e');
        _showMessage('Failed to save/upload image. Please check permissions and try again.');
      }
    } else {
      _showMessage('No image selected.');
    }
  }

  Future<void> _editProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneController = TextEditingController(text: _phoneNumber);

    try {
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder:
            (context) => AlertDialog(
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
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
                    final newPhoneNumber = phoneController.text.trim();

                    if (newName.isEmpty) {
                      _showMessage('Name cannot be empty');
                      return;
                    }

                    if (newPhoneNumber.isEmpty) {
                      _showMessage('Phone number cannot be empty');
                      return;
                    }

                    if (!RegExp(r'^\d{10,}$').hasMatch(newPhoneNumber)) {
                      _showMessage('Enter a valid phone number');
                      return;
                    }

                    await prefs.setString('username', newName);
                    await prefs.setString('phoneNumber', newPhoneNumber);

                    setState(() {
                      _nameController.text = newName;
                      _phoneNumber = newPhoneNumber;
                    });

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    _showMessage('Profile updated successfully!');
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
      );
    } finally {
      // Always dispose the controller to prevent memory leaks
      phoneController.dispose();
    }
  }



  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                        phoneNumber: _phoneNumber.isNotEmpty ? _phoneNumber : null,
                        onEditProfile: _editProfile,
                        onResetPassword: () {
                          _showMessage('Reset password functionality not implemented.');
                        },
                      ),
                    ),
                  ),
                  // PreferencesCard for currency, language, notifications
                  PreferencesCard(
                    notificationsEnabled: _notificationsEnabled,
                    selectedCurrency: _selectedCurrency,
                    selectedLanguage: _selectedLanguage,
                    onNotificationsChanged: (value) async {
                      setState(() => _notificationsEnabled = value);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notificationsEnabled', value);
                    },
                    onCurrencyChanged: (value) async {
                      if (value != null) {
                        setState(() => _selectedCurrency = value);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selectedCurrency', value);
                      }
                    },
                    onLanguageChanged: (value) async {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('selectedLanguage', value);
                      }
                    },
                  ),
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
