import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/models/item_model.dart';

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