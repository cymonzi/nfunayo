// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a file to Firebase Storage and returns the download URL.
  Future<String> uploadFile(File file, String path) async {
    try {
      // Determine the MIME type from the file extension
      final mimeType = _getMimeType(file.path);

      // Create a reference to the file in Firebase Storage
      final ref = _storage.ref().child(path);

      // Start the file upload
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: mimeType),
      );

      // Wait for the upload to complete
      final snapshot = await uploadTask.whenComplete(() {});

      // Check if the upload was successful
      if (snapshot.state == TaskState.success) {
        // Get the download URL of the uploaded file
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } else {
        throw Exception('Upload failed with state: ${snapshot.state}');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  /// Helper method to determine MIME type
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Deletes a file from Firebase Storage.
  Future<void> deleteFile(String filePath) async {
    try {
      final storageRef = _storage.ref(filePath);
      await storageRef.delete();
      print('File deleted successfully!');
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
}
