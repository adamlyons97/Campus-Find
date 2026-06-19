import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

final storageProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadItemImage(File imageFile, String userId) async {
    try {
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      final ref = _storage.ref().child('items').child(userId).child(fileName);

      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
      
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}