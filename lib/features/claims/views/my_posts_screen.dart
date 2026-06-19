import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../home/providers/item_provider.dart';
import '../providers/match_provider.dart';

class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myItemsState = ref.watch(myItemsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts & AI Alerts'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: myItemsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('You haven\'t reported any items yet.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User's Item Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.type.toUpperCase(),
                                    style: TextStyle(
                                      color: item.type == 'lost'
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // THE 3-TIER STATUS BADGE
                                  Builder(
                                    builder: (context) {
                                      Color badgeColor;
                                      Color textColor;
                                      String badgeText;

                                      if (item.status == 'resolved') {
                                        badgeColor = Colors.grey.shade300;
                                        textColor = Colors.grey.shade700;
                                        badgeText = 'RESOLVED';
                                      } else if (item.status == 'claimed') {
                                        badgeColor = Colors.orange.shade100;
                                        textColor = Colors.deepOrange;
                                        badgeText = 'CLAIMED';
                                      } else {
                                        badgeColor = Colors.blue.shade100;
                                        textColor = Colors.blue;
                                        badgeText = 'ACTIVE';
                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          badgeText,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              Text(
                                item.categoryName,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(item.description),
                        ],
                      ),
                    ),

                    // DYNAMIC BOTTOM SECTION BASED ON STATUS
                    if (item.status == 'resolved') ...[
                      // If resolved, show a simple closed case message
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Case Closed. Item returned successfully.',
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ] else if (item.status == 'claimed') ...[
                      // If claimed, show the handover button AND the cancel button!
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Meeting in progress. Please verify the item in person.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.deepOrange),
                            ),
                            const SizedBox(height: 12),
                            // THE GREEN SUCCESS BUTTON
                            ElevatedButton.icon(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection('items')
                                    .doc(item.itemId)
                                    .set({
                                      'status': 'resolved',
                                    }, SetOptions(merge: true));
                              },
                              icon: const Icon(Icons.handshake),
                              label: const Text(
                                'CONFIRM HANDOVER (RESOLVE)',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // THE NEW RED CANCEL BUTTON
                            TextButton.icon(
                              onPressed: () async {
                                // Revert the item back to the Active hunting state!
                                await FirebaseFirestore.instance
                                    .collection('items')
                                    .doc(item.itemId)
                                    .set({
                                      'status': 'active',
                                    }, SetOptions(merge: true));

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Claim cancelled. Item returned to ACTIVE status.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.cancel, size: 18),
                              label: const Text(
                                'Not my item (Cancel Claim)',
                                style: TextStyle(fontSize: 13),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // If active, show the AI Match Engine Listener
                      Consumer(
                        builder: (context, ref, child) {
                          final matchState = ref.watch(
                            itemMatchesStreamProvider(item.itemId),
                          );

                          return matchState.when(
                            loading: () => const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: LinearProgressIndicator()),
                            ),
                            error: (err, stack) => Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                err.toString(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            data: (matches) {
                              if (matches.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    '⏳ AI Scanning active. No matches yet.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.auto_awesome,
                                          color: Colors.amber,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Gemini AI Match Detected!',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        final match = matches.first;
                                        final targetItemId =
                                            match.newItemId == item.itemId
                                            ? match.matchedItemId
                                            : match.newItemId;
                                        context.push(
                                          '/match-details?matchId=${match.matchId}&matchedItemId=$targetItemId',
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                      ),
                                      child: const Text('REVIEW MATCH'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
