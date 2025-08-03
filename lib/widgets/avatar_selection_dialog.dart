import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AvatarSelectionDialog extends StatelessWidget {
  final List<String> avatars;
  final Function(String?) onAvatarSelected;
  final VoidCallback onAddImage;
  final VoidCallback onDeleteImage;

  const AvatarSelectionDialog({
    super.key,
    required this.avatars,
    required this.onAvatarSelected,
    required this.onAddImage,
    required this.onDeleteImage,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Avatar or Add Image'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
        child:
            avatars.isEmpty
                ? const Center(child: Text('No avatars available'))
                : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount:
                      avatars.length + 2, // Add 2 for image and delete options
                  itemBuilder: (context, index) {
                    if (index == avatars.length) {
                      // Add Image Option
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onAddImage();
                        },
                        child: Column(
                          children: const [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blueAccent,
                              child: Icon(Icons.image, color: Colors.white),
                            ),
                            SizedBox(height: 8),
                            Text('Add Image', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    } else if (index == avatars.length + 1) {
                      // Delete Image Option
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onDeleteImage();
                        },
                        child: Column(
                          children: const [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.redAccent,
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Delete Image',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    } else {
                      // Avatar Options
                      final avatar = avatars[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          onAvatarSelected(avatar);
                        },
                        child:
                            avatar.endsWith('.json')
                                ? Lottie.asset(
                                  'assets/animations/$avatar',
                                  width: 80,
                                  height: 80,
                                )
                                : CircleAvatar(
                                  radius: 30,
                                  backgroundImage: AssetImage(
                                    'assets/images/$avatar',
                                  ),
                                ),
                      );
                    }
                  },
                ),
      ),
    );
  }
}
