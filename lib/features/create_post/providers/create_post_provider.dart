import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/item_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/item_repository.dart';
import '../../../data/services/gemini_ai_service.dart';

/// Categories for the form dropdown (falls back to defaults if empty).
final categoriesProvider = FutureProvider.autoDispose<List<CategoryModel>>(
  (ref) => ref.watch(itemRepositoryProvider).fetchCategories(),
);

/// Outcome of creating an item, optionally carrying AI match suggestions.
class CreatePostResult {
  final String itemId;
  final List<AiMatch> suggestedMatches;
  const CreatePostResult(this.itemId, this.suggestedMatches);
}

/// Handles the full create flow: upload image → write item → run the Gemini
/// matcher against the opposite item type (Feature 3 — Smart Match).
class CreatePostController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CreatePostResult?> submit({
    required String title,
    required String description,
    required String type, // ItemType.lost | found
    required CategoryModel category,
    required String locationName,
    required String locationDetails,
    XFile? image,
    String? finderClaimRequestNotes,
  }) async {
    final repo = ref.read(itemRepositoryProvider);
    final auth = ref.read(authRepositoryProvider).currentUser;
    if (auth == null) {
      state = AsyncError('Not signed in', StackTrace.current);
      return null;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard<CreatePostResult>(() async {
      String? imageUrl;
      if (image != null) {
        final bytes = await image.readAsBytes();
        imageUrl = await repo.uploadImage(bytes, auth.uid).timeout(
              const Duration(seconds: 30),
              onTimeout: () => throw Exception(
                'Image upload timed out. Check that Firebase Storage is '
                'enabled and its rules are deployed, then try again.',
              ),
            );
      }

      final item = ItemModel(
        id: '',
        title: title.trim(),
        description: description.trim(),
        type: type,
        status: ItemStatus.active,
        categoryId: category.id,
        categoryName: category.name,
        imageUrl: imageUrl,
        locationSeen: ItemLocation(
          name: locationName.trim(),
          specificDetails: locationDetails.trim(),
        ),
        reportedAt: DateTime.now(),
        reporterId: auth.uid,
        reporterName: auth.displayName ?? auth.email ?? 'Member',
        finderClaimRequestNotes: finderClaimRequestNotes?.trim(),
      );

      final id = await repo.createItem(item);
      final created = item.copyWith();

      // Run AI matching against the opposite type. This is best-effort and
      // strictly time-boxed: the post must succeed even if the AI call stalls
      // (e.g. a slow network or a missing/invalid GEMINI_API_KEY).
      final opposite =
          type == ItemType.lost ? ItemType.found : ItemType.lost;
      var matches = <AiMatch>[];
      try {
        final candidates = await repo
            .fetchActiveByType(opposite)
            .timeout(const Duration(seconds: 10));
        matches = await ref
            .read(geminiAiServiceProvider)
            .findMatches(query: created, candidates: candidates)
            .timeout(const Duration(seconds: 15), onTimeout: () => <AiMatch>[]);
      } catch (_) {
        // AI matching is best-effort; the post still succeeds without it.
      }

      return CreatePostResult(id, matches);
    });

    state = result.hasError
        ? AsyncError(result.error!, result.stackTrace!)
        : const AsyncData(null);
    return result.valueOrNull;
  }
}

final createPostControllerProvider =
    AutoDisposeAsyncNotifierProvider<CreatePostController, void>(
  CreatePostController.new,
);
