import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/services/gemini_ai_service.dart';

/// A resolved AI match paired with the full item for display.
class SearchHit {
  final ItemModel item;
  final int confidence;
  final String reason;
  const SearchHit(this.item, this.confidence, this.reason);
}

/// Runs a free-text description through Gemini against active found items.
class GeminiSearchController
    extends AutoDisposeAsyncNotifier<List<SearchHit>> {
  @override
  Future<List<SearchHit>> build() async => [];

  /// [searchType] decides which pool to search: describing a LOST item
  /// searches FOUND listings, and vice versa.
  Future<void> search({
    required String description,
    String searchType = ItemType.found,
  }) async {
    if (description.trim().isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(itemRepositoryProvider);
      final ai = ref.read(geminiAiServiceProvider);

      if (!ai.isConfigured) {
        throw 'Gemini API key not configured. See SETUP.md.';
      }

      final candidates = await repo.fetchActiveByType(searchType);

      // Build a lightweight query item from the free-text description.
      final query = ItemModel(
        id: 'query',
        title: 'User search',
        description: description.trim(),
        type: searchType == ItemType.found ? ItemType.lost : ItemType.found,
        status: ItemStatus.active,
        categoryId: '',
        categoryName: 'General',
        reportedAt: DateTime.now(),
        reporterId: '',
        reporterName: '',
      );

      final matches =
          await ai.findMatches(query: query, candidates: candidates);
      final byId = {for (final c in candidates) c.id: c};

      return matches
          .where((m) => byId.containsKey(m.itemId))
          .map((m) => SearchHit(byId[m.itemId]!, m.confidence, m.reason))
          .toList();
    });
  }
}

final geminiSearchControllerProvider = AutoDisposeAsyncNotifierProvider<
    GeminiSearchController, List<SearchHit>>(
  GeminiSearchController.new,
);
