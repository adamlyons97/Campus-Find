import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/models/item_model.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

// Provides a global instance of the ItemRepository
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

// A live stream provider that auto-updates UI when a LOST item is added to Firestore
final lostItemsStreamProvider = StreamProvider.autoDispose<List<ItemModel>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getActiveLostItemsStream();
});

// A live stream provider that auto-updates UI when a FOUND item is added to Firestore
final foundItemsStreamProvider = StreamProvider.autoDispose<List<ItemModel>>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getActiveFoundItemsStream();
});

// Streams all items reported by the currently logged-in user
final myItemsStreamProvider = StreamProvider.autoDispose<List<ItemModel>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('items')
      .where('reportedBy', isEqualTo: userId)
      .where('isSoftDeleted', isEqualTo: false)
      .orderBy('reportedAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return ItemModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
});