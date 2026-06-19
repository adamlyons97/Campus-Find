import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

final storageProvider = Provider<StorageService>((ref) => StorageService());

class StorageService {
  static const int _maxInlineImageBytes = 650000;

  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> saveItemImage(
    Uint8List imageBytes,
    String userId,
    String originalFileName,
  ) async {
    final fileExtension = path.extension(originalFileName).toLowerCase();
    final contentType = _contentTypeFor(fileExtension);

    try {
      final effectiveExtension = fileExtension.isEmpty ? '.jpg' : fileExtension;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}$effectiveExtension';

      final ref = _storage.ref().child('items').child(userId).child(fileName);

      final uploadTask = await ref.putData(
        imageBytes,
        SettableMetadata(contentType: contentType),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (error, stackTrace) {
      developer.log(
        'Image upload failed',
        name: 'campus_find.storage',
        error: error,
        stackTrace: stackTrace,
      );

      if (imageBytes.lengthInBytes > _maxInlineImageBytes) {
        throw Exception(
          'The image is too large to save. Please select a smaller image.',
        );
      }

      // Firestore fallback keeps image submission working when Firebase Storage
      // is unavailable or its project rules have not yet been configured.
      return 'data:$contentType;base64,${base64Encode(imageBytes)}';
    }
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.jpeg':
      case '.jpg':
      default:
        return 'image/jpeg';
    }
  }
}
