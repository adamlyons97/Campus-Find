import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            return const Center(child: Text('You haven\'t reported any items yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // User's Item Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.type.toUpperCase(),
                                style: TextStyle(
                                  color: item.type == 'lost' ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(item.categoryName, style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(item.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(item.description),
                        ],
                      ),
                    ),

                    // The AI Match Engine Listener
                    Consumer(
                      builder: (context, ref, child) {
                        final matchState = ref.watch(itemMatchesStreamProvider(item.itemId));

                        return matchState.when(
                          loading: () => const Padding(padding: EdgeInsets.all(16), child: Center(child: LinearProgressIndicator())),
                          error: (err, stack) => Padding(padding: const EdgeInsets.all(16), child: Text(err.toString(), style: const TextStyle(color: Colors.red))),
                          data: (matches) {
                            if (matches.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('⏳ AI Scanning active. No matches yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                              );
                            }

                            // AI MATCH FOUND UI
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.auto_awesome, color: Colors.amber),
                                      const SizedBox(width: 8),
                                      const Text('Gemini AI Match Detected!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                      const Spacer(),
                                      Text('${(matches.first.confidenceScore * 100).toInt()}% Match'),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('A highly probable match has been found in the system. Review it now to coordinate the return.'),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      final match = matches.first;
                                      
                                      // SMART ROUTING LOGIC:
                                      // If the user's item is the 'newItem', show them the 'matchedItem'.
                                      // If the user's item is the 'matchedItem', show them the 'newItem'.
                                      final targetItemId = match.newItemId == item.itemId 
                                          ? match.matchedItemId 
                                          : match.newItemId;

                                      // Push to the new screen, passing the IDs in the URL
                                      context.push('/match-details?matchId=${match.matchId}&matchedItemId=$targetItemId');
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                                    child: const Text('REVIEW MATCH'),
                                  )
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
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