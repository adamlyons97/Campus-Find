import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_model.dart';

class ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // The main collection reference
  CollectionReference get _itemsCollection => _firestore.collection('items');

  /// Creates a new Lost or Found item post in Firestore
  Future<String> createItem(ItemModel item) async {
    try {
      // Create a new document reference with an auto-generated ID
      DocumentReference docRef = _itemsCollection.doc();
      
      // We need to inject the auto-generated ID back into the model before saving
      ItemModel itemWithId = ItemModel(
        itemId: docRef.id,
        title: item.title,
        description: item.description,
        type: item.type,
        status: item.status,
        categoryId: item.categoryId,
        categoryName: item.categoryName,
        imageUrl: item.imageUrl,
        locationSeen: item.locationSeen,
        reportedAt: item.reportedAt,
        reportedBy: item.reportedBy,
        reportedByName: item.reportedByName,
        isSoftDeleted: item.isSoftDeleted,
        finderClaimRequestNotes: item.finderClaimRequestNotes,
      );

      await docRef.set(itemWithId.toMap());
      
      // TODO: Trigger the Gemini AI Smart Match background service here later

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create item: $e');
    }
  }

  /// Streams all ACTIVE LOST items, ordered by newest first
  Stream<List<ItemModel>> getActiveLostItemsStream() {
    return _itemsCollection
        .where('type', isEqualTo: 'lost')
        .where('status', isEqualTo: 'active')
        .where('isSoftDeleted', isEqualTo: false)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Streams all ACTIVE FOUND items, ordered by newest first
  Stream<List<ItemModel>> getActiveFoundItemsStream() {
    return _itemsCollection
        .where('type', isEqualTo: 'found')
        .where('status', isEqualTo: 'active')
        .where('isSoftDeleted', isEqualTo: false)
        .orderBy('reportedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
  /// Fetches a one-time list of active items by type (used by the AI matching service)
  Future<List<ItemModel>> getActiveItemsByTypeOnce(String type) async {
    try {
      final snapshot = await _itemsCollection
          .where('type', isEqualTo: type)
          .where('status', isEqualTo: 'active')
          .where('isSoftDeleted', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch items for AI comparison: $e');
    }
  }
}

