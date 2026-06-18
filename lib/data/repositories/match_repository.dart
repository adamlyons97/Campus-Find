import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match_model.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _matchesCollection => _firestore.collection('matches');

  /// Streams all matches associated with a specific item ID
  Stream<List<MatchModel>> getMatchesForItem(String itemId) {
    // Because the item could either be the "new" item or the "existing" item 
    // in the match pair, we use an OR query (requires Firestore v4.4.0+)
    return _matchesCollection
        .where(
          Filter.or(
            Filter('newItemId', isEqualTo: itemId),
            Filter('matchedItemId', isEqualTo: itemId),
          ),
        )
        .where('status', isEqualTo: 'pending_review')
        .orderBy('detectedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MatchModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  /// Updates the status of a match (e.g., when a user accepts or rejects it)
  Future<void> updateMatchStatus(String matchId, String newStatus) async {
    await _matchesCollection.doc(matchId).update({'status': newStatus});
  }
}