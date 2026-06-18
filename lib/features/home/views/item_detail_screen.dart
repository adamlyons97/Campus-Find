import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/item_model.dart';

// 1. Provider to fetch the specific item
final specificItemProvider = FutureProvider.family<ItemModel?, String>((ref, itemId) async {
  final doc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
  if (!doc.exists) return null;
  return ItemModel.fromMap(doc.data()!, doc.id);
});

// 2. Provider to fetch the reporter's real name from the 'users' collection
final reporterNameProvider = FutureProvider.family<String, String>((ref, userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (!doc.exists) return 'Anonymous Student';
  return doc.data()?['fullName'] ?? 'Anonymous Student';
});

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemState = ref.watch(specificItemProvider(itemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: itemState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (item) {
          if (item == null) return const Center(child: Text('Item not found.'));

          final date = item.reportedAt;
          final dateString = '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            // THIS is the secret to centering everything: Force the column to be full width
            child: SizedBox(
              width: double.infinity, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center, // Center the entire column!
                children: [
                  // BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: item.type == 'found' ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.type == 'found' ? 'FOUND ITEM' : 'LOST ITEM',
                      style: TextStyle(
                        color: item.type == 'found' ? Colors.green.shade900 : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // TITLE & DESCRIPTION
                  Text(item.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(item.categoryName, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.teal.shade700, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Text(item.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // LOCATION INFO (Centered Stack)
                  const Text('Location Details', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Icon(Icons.location_on, color: Colors.teal, size: 36),
                  const SizedBox(height: 8),
                  Text(item.locationSeen.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  if (item.locationSeen.specificDetails.isNotEmpty)
                    Text(item.locationSeen.specificDetails, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // REPORTER INFO (Centered Stack)
                  const Text('Report Information', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.teal, size: 28),
                        const SizedBox(height: 8),
                        Text(dateString, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
                        
                        const SizedBox(height: 24),
                        
                        const Icon(Icons.person, color: Colors.teal, size: 28),
                        const SizedBox(height: 8),
                        const Text('Reported by:', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Consumer(
                          builder: (context, ref, child) {
                            final nameState = ref.watch(reporterNameProvider(item.reportedBy));
                            return nameState.when(
                              loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (e, s) => const Text('Unknown User'),
                              data: (name) => Text(
                                name, 
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}