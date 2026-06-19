import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/providers/item_provider.dart';
import '../../../data/models/item_model.dart';
import '../../../data/services/ai_match_service.dart'; // NEW

final createPostControllerProvider = StateNotifierProvider<CreatePostController, AsyncValue<String?>>((ref) {
  return CreatePostController(ref);
});

class CreatePostController extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;

  CreatePostController(this._ref) : super(const AsyncValue.data(null));

  Future<void> submitItem({
    required String title,
    required String description,
    required String type,
    required String categoryId,
    required String categoryName,
    required String locationName,
    required String locationDetails,
    String? imageUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User session not found.');

      final location = LocationSeen(
        name: locationName,
        specificDetails: locationDetails,
      );

      final newItem = ItemModel(
        itemId: '', 
        title: title,
        description: description,
        type: type,
        categoryId: categoryId,
        categoryName: categoryName,
        locationSeen: location,
        imageUrl: imageUrl,
        reportedAt: DateTime.now(),
        reportedBy: currentUser.uid,
        reportedByName: currentUser.displayName ?? currentUser.email!.split('@')[0],
      );

      // 1. Write the new item to the cloud database
      final itemId = await _ref.read(itemRepositoryProvider).createItem(newItem);
      
      // 2. Run the AI Intelligent Matching Routine in the background
      _runAiMatchRoutine(newItem, itemId);

      state = AsyncValue.data(itemId);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Private background routine to evaluate cross-references using Gemini AI
  Future<void> _runAiMatchRoutine(ItemModel item, String generatedId) async {
    try {
      // Determine target comparison lane (opposite classification type)
      final targetType = (item.type == 'lost') ? 'found' : 'lost';
      
      // Pull a one-time list of alternative candidates
      final candidates = await _ref.read(itemRepositoryProvider).getActiveItemsByTypeOnce(targetType);
      
      if (candidates.isEmpty) return;

      // Reconstruct the model with its real document ID included
      final itemWithId = ItemModel(
        itemId: generatedId,
        title: item.title,
        description: item.description,
        type: item.type,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        locationSeen: item.locationSeen,
        reportedAt: item.reportedAt,
        reportedBy: item.reportedBy,
        reportedByName: item.reportedByName,
      );

      // Execute the Gemini context evaluation
      final matchedId = await _ref.read(aiMatchServiceProvider).findPotentialMatch(
            newItem: itemWithId,
            existingItems: candidates,
          );

      // 3. If Gemini detects an overlapping match signature, record it in Firestore
      if (matchedId != null) {
        await FirebaseFirestore.instance.collection('matches').add({
          'newItemId': generatedId,
          'matchedItemId': matchedId,
          'detectedAt': DateTime.now(),
          'confidenceScore': 0.85, // Minimum validation baseline set in system prompt
          'status': 'pending_review',
        });
        print('★ SUCCESS: Gemini AI detected an automated system match link: Document ID $matchedId');
      }
    } catch (aiError) {
      // Fail gracefully so the user's primary post submission isn't interrupted
      print('Background AI Matching Engine warning: $aiError');
    }
  }
}