import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';

/// Current feed filter: null = all, 'lost', or 'found'.
final feedFilterProvider = StateProvider<String?>((ref) => null);

/// Live, real-time list of active items (Section 9 — Firestore streams).
final itemFeedProvider = StreamProvider.autoDispose<List<ItemModel>>((ref) {
  final filter = ref.watch(feedFilterProvider);
  return ref.watch(itemRepositoryProvider).watchItems(type: filter);
});

/// Live list of the current user's own reports.
final myItemsProvider =
    StreamProvider.autoDispose.family<List<ItemModel>, String>((ref, uid) {
  return ref.watch(itemRepositoryProvider).watchMyItems(uid);
});

/// Live single item, used by the detail screen.
final itemByIdProvider =
    StreamProvider.autoDispose.family<ItemModel?, String>((ref, id) {
  return ref.watch(itemRepositoryProvider).watchItem(id);
});

// ---- Browse screen state ----

/// Live list of every non-deleted item (any status) for the Browse screen.
final allItemsProvider = StreamProvider.autoDispose<List<ItemModel>>((ref) {
  return ref.watch(itemRepositoryProvider).watchAllItems();
});

/// Browse filter chip: 'all' | 'lost' | 'found' | 'returned'.
final browseFilterProvider = StateProvider.autoDispose<String>((ref) => 'all');

/// Free-text search query for the Browse screen.
final browseQueryProvider = StateProvider.autoDispose<String>((ref) => '');
