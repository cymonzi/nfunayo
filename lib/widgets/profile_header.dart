import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final String email;
  final File? customImage;
  final String? avatarUrl;
  final ValueChanged<dynamic> onEditAvatar; // Accept File (mobile) or Uint8List (web)

  const ProfileHeader({
    super.key,
    required this.username,
    required this.email,
    required this.customImage,
    required this.onEditAvatar,
    this.avatarUrl,
  });

  void _showAvatarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Keep Current Avatar'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Upload New Image'),
                onTap: () async {
                  Navigator.pop(context);
                  final ImagePicker picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    if (kIsWeb) {
                      // Web: get bytes and pass to parent
                      final bytes = await pickedFile.readAsBytes();
                      onEditAvatar(bytes);
                    } else {
                      // Mobile/desktop: pass File
                      onEditAvatar(File(pickedFile.path));
                    }
                  } else {
                    onEditAvatar(null);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const Text(
              'Tap to change image',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _showAvatarOptions(context),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: customImage != null
                        ? ClipOval(
                            child: Image.file(
                              customImage!,
                              fit: BoxFit.cover,
                              width: 110,
                              height: 110,
                            ),
                          )
                        : avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  avatarUrl!,
                                  fit: BoxFit.cover,
                                  width: 110,
                                  height: 110,
                                  errorBuilder: (context, error, stackTrace) => Lottie.asset(
                                    'assets/animations/avatarx.json',
                                    width: 110,
                                    height: 110,
                                  ),
                                ),
                              )
                            : Lottie.asset(
                                'assets/animations/avatarx.json',
                                width: 110,
                                height: 110,
                              ),
                  ),
                ),
            const SizedBox(height: 16),
            Text(
              username,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            // ...existing code...
          ],
        ),
      ),
    );
  }

}
