import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW: For opening WhatsApp & Phone calls
import '../../../data/models/item_model.dart';
import '../providers/match_provider.dart';

// Fetches the specific matched item once
final singleItemFutureProvider = FutureProvider.family<ItemModel?, String>((
  ref,
  itemId,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('items')
      .doc(itemId)
      .get();
  if (!doc.exists) return null;
  return ItemModel.fromMap(doc.data()!, doc.id);
});

// NEW: Fetches the Reporter's full profile from the 'users' collection to get their phone number!
final reporterProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.data();
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
    final itemState = ref.watch(singleItemFutureProvider(matchedItemId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review AI Match'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: itemState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.amber)),
        error: (err, stack) => Center(child: Text('Error loading item: $err')),
        data: (item) {
          if (item == null) {
            return const Center(
              child: Text('Item no longer exists in the database.'),
            );
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: item.type == 'found'
                                ? Colors.green.shade100
                                : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.type == 'found'
                                ? 'SOMEONE FOUND THIS'
                                : 'SOMEONE LOST THIS',
                            style: TextStyle(
                              color: item.type == 'found'
                                  ? Colors.green.shade900
                                  : Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),

                        const Divider(height: 32),

                        // Location Section
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Location Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.locationSeen.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          item.locationSeen.specificDetails,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),

                        const Divider(height: 32),

                        // LIVE SECTION: Reporter Contact Details from Firestore
                        const Row(
                          children: [
                            Icon(Icons.person_pin, color: Colors.teal),
                            SizedBox(width: 8),
                            Text(
                              'Reporter Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // NEW: A Consumer that waits for the user profile to load from Firestore
                        Consumer(
                          builder: (context, ref, child) {
                            final reporterState = ref.watch(
                              reporterProfileProvider(item.reportedBy),
                            );

                            return reporterState.when(
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (err, stack) => const Text(
                                'Could not load reporter details.',
                                style: TextStyle(color: Colors.red),
                              ),
                              data: (reporterData) {
                                // Extract the real data from the database
                                final phone =
                                    reporterData?['phoneNumber'] ?? '';
                                final matric =
                                    reporterData?['matricNumber'] ??
                                    item.reportedByName;

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Colors.teal.shade50,
                                          child: const Icon(
                                            Icons.person,
                                            color: Colors.teal,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Matric ID: $matric',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              Text(
                                                phone.isNotEmpty
                                                    ? 'Phone: $phone'
                                                    : 'No phone number provided',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // REAL Contact Action Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: phone.isEmpty
                                                ? null
                                                : () async {
                                                    // Clean the phone number and add Malaysian country code if needed
                                                    String formattedPhone =
                                                        phone.replaceAll(
                                                          RegExp(r'[^0-9]'),
                                                          '',
                                                        );
                                                    if (formattedPhone
                                                        .startsWith('0')) {
                                                      formattedPhone =
                                                          '6$formattedPhone';
                                                    }

                                                    final Uri
                                                    whatsappUrl = Uri.parse(
                                                      'https://wa.me/$formattedPhone',
                                                    );

                                                    try {
                                                      await launchUrl(
                                                        whatsappUrl,
                                                        mode: LaunchMode
                                                            .externalApplication,
                                                      );
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Could not launch WhatsApp',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.chat,
                                              size: 18,
                                            ),
                                            label: const Text('WhatsApp'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF25D366,
                                              ),
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.grey.shade300,
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: phone.isEmpty
                                                ? null
                                                : () async {
                                                    final Uri phoneUrl =
                                                        Uri.parse('tel:$phone');
                                                    try {
                                                      await launchUrl(phoneUrl);
                                                    } catch (e) {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Could not open phone dialer',
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    }
                                                  },
                                            icon: const Icon(
                                              Icons.phone,
                                              size: 18,
                                            ),
                                            label: const Text('Call'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.blue.shade600,
                                              foregroundColor: Colors.white,
                                              disabledBackgroundColor:
                                                  Colors.grey.shade300,
                                              elevation: 0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Decision Buttons
                ElevatedButton.icon(
                  onPressed: () async {
                    final db = FirebaseFirestore.instance;

                    // 1. Update match status to accepted
                    await ref
                        .read(matchRepositoryProvider)
                        .updateMatchStatus(matchId, 'accepted');

                    // 2. Fetch the match document to find both items connected by the bridge
                    final matchDoc = await db
                        .collection('matches')
                        .doc(matchId)
                        .get();

                    if (matchDoc.exists) {
                      final matchData = matchDoc.data()!;
                      final firstItemId = matchData['newItemId'];
                      final secondItemId = matchData['matchedItemId'];

                      // 3. STATUS MANAGEMENT: Mark BOTH items as CLAIMED in Firestore!
                      await db.collection('items').doc(firstItemId).set({
                        'status': 'claimed',
                      }, SetOptions(merge: true));
                      await db.collection('items').doc(secondItemId).set({
                        'status': 'claimed',
                      }, SetOptions(merge: true));
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Match Accepted! Item is now CLAIMED. Please arrange a meet-up.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      context.pop(); // Go back to dashboard
                    }
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text(
                    'YES, THIS IS IT (ACCEPT)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                    await ref
                        .read(matchRepositoryProvider)
                        .updateMatchStatus(matchId, 'rejected');
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Match Rejected. AI will keep scanning.',
                          ),
                        ),
                      );
                      context.pop(); // Go back to dashboard
                    }
                  },
                  icon: const Icon(Icons.cancel),
                  label: const Text('No, not a match (Reject)'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
