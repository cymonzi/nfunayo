import 'package:flutter/material.dart';

class ProfileDetails extends StatelessWidget {
  // Remove phoneNumber parameter
  final VoidCallback onEditProfile;
  final VoidCallback onResetPassword;

  const ProfileDetails({
    super.key,
    required this.onEditProfile,
    required this.onResetPassword,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ...existing code...
          const Divider(height: 30),
          _profileTile(
            icon: Icons.edit,
            iconColor: Colors.green,
            title: 'Edit Profile',
            onTap: onEditProfile,
          ),
      
        ],
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        // ignore: deprecated_member_use
        backgroundColor: iconColor.withOpacity(0.1),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle:
          subtitle != null
              ? Text(subtitle, style: const TextStyle(color: Colors.black54))
              : null,
      trailing:
          onTap != null
              ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              )
              : null,
      onTap: onTap,
    );
  }
}
