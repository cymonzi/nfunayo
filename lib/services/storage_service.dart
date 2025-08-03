import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:typed_data';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  UploadTask? _currentUploadTask; // Track the current upload task

  Future<void> uploadFileWithProgress({
    required Function(double progress) onProgress,
    required Function onCancel,
  }) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      onCancel();
      return;
    }

    // Compress the image
    Uint8List fileBytes = await image.readAsBytes();
    Uint8List? compressedBytes = await FlutterImageCompress.compressWithList(
      fileBytes,
      quality: 70, // Adjust quality (0-100)
    );

    // ignore: unnecessary_null_comparison
    if (compressedBytes == null) {
      onCancel();
      return;
    }

    final storageRef = _storage.ref().child(
      'uploads/${DateTime.now().millisecondsSinceEpoch}_${image.name}',
    );

    _currentUploadTask = storageRef.putData(compressedBytes);

    _currentUploadTask!.snapshotEvents.listen(
      (TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      },
      onError: (error) {
        // ignore: avoid_print
        print('Upload error: $error'); // Log the error
        onCancel();
      },
    );

    try {
      await _currentUploadTask;
    } catch (e) {
      // ignore: avoid_print
      print('Error in uploadFileWithProgress: $e'); // Log the error
      onCancel();
    }
  }

  void cancelUpload() {
    _currentUploadTask?.cancel();
  }
}
