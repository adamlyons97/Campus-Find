import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/item_model.dart';
import '../providers/match_provider.dart';

// A quick Riverpod provider to fetch the specific matched item once
final singleItemFutureProvider = FutureProvider.family<ItemModel?, String>((ref, itemId) async {
  final doc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
  if (!doc.exists) return null;
  return ItemModel.fromMap(doc.data()!, doc.id);
});

class MatchDetailsScreen extends ConsumerWidget {
  final String matchId;
  final String matchedItemId;

  const MatchDetailsScreen({
    super.key,
    required this.matchId,
    required this.matchedItemId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the future provider to load the item
    final itemState = ref.watch(singleItemFutureProvider(matchedItemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review AI Match'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: itemState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(child: Text('Error loading item: $err')),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item no longer exists in the database.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.auto_awesome, size: 64, color: Colors.amber),
                const SizedBox(height: 16),
                const Text(
                  'Is this your item?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),

                // The Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: item.type == 'found' ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.type == 'found' ? 'SOMEONE FOUND THIS' : 'SOMEONE LOST THIS',
                            style: TextStyle(
                              color: item.type == 'found' ? Colors.green.shade900 : Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(item.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(item.description, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                        const Divider(height: 32),
                        
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.teal),
                            SizedBox(width: 8),
                            Text('Location Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(item.locationSeen.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(item.locationSeen.specificDetails, style: Colors.grey.shade700 == null ? null : TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Decision Buttons
                // Decision Buttons
                ElevatedButton.icon(
                  onPressed: () async {
                    final db = FirebaseFirestore.instance;

                    // 1. Update match status to accepted
                    await ref.read(matchRepositoryProvider).updateMatchStatus(matchId, 'accepted');
                    
                    // 2. Fetch the match document to find both items connected by the bridge
                    final matchDoc = await db.collection('matches').doc(matchId).get();
                    
                    if (matchDoc.exists) {
                      final matchData = matchDoc.data()!;
                      final firstItemId = matchData['newItemId'];
                      final secondItemId = matchData['matchedItemId'];

                      // 3. STATUS MANAGEMENT: Mark BOTH items as resolved in Firestore!
                      await db.collection('items').doc(firstItemId).set({'status': 'resolved'}, SetOptions(merge: true));
                      await db.collection('items').doc(secondItemId).set({'status': 'resolved'}, SetOptions(merge: true));
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Match Accepted! Both items marked as resolved.'), backgroundColor: Colors.green),
                      );
                      context.pop(); // Go back to dashboard
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('YES, THIS IS IT (ACCEPT)', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    // Update match status to rejected
                    await ref.read(matchRepositoryProvider).updateMatchStatus(matchId, 'rejected');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Match Rejected. AI will keep scanning.')),
                      );
                      context.pop(); // Go back to dashboard
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('No, not a match (Reject)'),
                  style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}