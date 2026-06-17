import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../home/providers/item_provider.dart';
import '../../../data/models/item_model.dart';

/// Controller to handle loading and error states during item submission
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

      // Prepare the Location sub-object
      final location = LocationSeen(
        name: locationName,
        specificDetails: locationDetails,
      );

      // Create the item data structural model
      final newItem = ItemModel(
        itemId: '', // Will be overwritten by auto-generated Firestore ID
        title: title,
        description: description,
        type: type,
        categoryId: categoryId,
        categoryName: categoryName,
        locationSeen: location,
        imageUrl: imageUrl,
        reportedAt: DateTime.now(),
        reportedBy: currentUser.uid,
        // Fallback to email prefix if display name hasn't populated yet
        reportedByName: currentUser.displayName ?? currentUser.email!.split('@')[0],
      );

      // Call our existing repository to push to the cloud
      final itemId = await _ref.read(itemRepositoryProvider).createItem(newItem);
      
      state = AsyncValue.data(itemId);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}