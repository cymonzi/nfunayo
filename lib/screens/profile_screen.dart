import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../widgets/profile_cards.dart';
import '../widgets/profile_details.dart';
import '../widgets/preferences_card.dart';
import '../utils/error_handler.dart';

class SettingsScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const SettingsScreen({super.key, required this.userName, required this.userEmail});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentUserName = '';
  String _currentUserEmail = '';
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
    
    // Load user info from SharedPreferences (from registration/login)
    final storedUserName = prefs.getString('userName') ?? '';
    final storedUserEmail = prefs.getString('userEmail') ?? '';
    
    setState(() {
      // Use stored user info if available, otherwise fall back to widget values
      _currentUserName = storedUserName.isNotEmpty ? storedUserName : widget.userName;
      _currentUserEmail = storedUserEmail.isNotEmpty ? storedUserEmail : widget.userEmail;
      
      final customImagePath = prefs.getString('customImagePath');
      if (customImagePath != null) {
        _customImage = File(customImagePath);
      }
      // Load avatar URL if exists
      _avatarUrl = prefs.getString('avatarUrl') ?? prefs.getString('userAvatar');
      _nameController.text = _currentUserName;
      
      // Load preferences
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _selectedCurrency = prefs.getString('selectedCurrency') ?? 'USD';
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
      _isLoading = false;
    });
    
    debugPrint('Loaded user details:');
    debugPrint('Name: $_currentUserName');
    debugPrint('Email: $_currentUserEmail');
    debugPrint('Avatar URL: $_avatarUrl');
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
    final nameController = TextEditingController(text: _currentUserName);
    final emailController = TextEditingController(text: _currentUserEmail);
    final formKey = GlobalKey<FormState>();

    try {
      await showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Edit Profile'),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name cannot be empty';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: Colors.blue),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email cannot be empty';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newName = nameController.text.trim();
                  final newEmail = emailController.text.trim();

                  try {
                    // Save to SharedPreferences
                    await prefs.setString('userName', newName);
                    await prefs.setString('userEmail', newEmail);

                    setState(() {
                      _currentUserName = newName;
                      _currentUserEmail = newEmail;
                    });
                    
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    _showMessage('Profile updated successfully!', isSuccess: true);
                  } catch (e) {
                    _showMessage('Failed to update profile: ${e.toString()}', isError: true);
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      );
    } finally {
      // Dispose controllers after dialog is dismissed
      nameController.dispose();
      emailController.dispose();
    }
  }

  void _showMessage(String message, {bool isSuccess = false, bool isError = false}) {
    if (isSuccess) {
      ErrorHandler.showSuccessSnackBar(context, message);
    } else if (isError) {
      ErrorHandler.showErrorSnackBar(context, message);
    } else {
      ErrorHandler.showInfoSnackBar(context, message);
    }
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
                    userName: _currentUserName.isNotEmpty ? _currentUserName : 'User',
                    userEmail: _currentUserEmail.isNotEmpty ? _currentUserEmail : 'user@example.com',
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
                          _showMessage('Reset password functionality will redirect to Firebase Auth.');
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
