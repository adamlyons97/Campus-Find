import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../../../data/models/item_model.dart';
import '../../claims/views/claim_submission_screen.dart';

// 1. Provider to fetch the specific item
final specificItemProvider = FutureProvider.family<ItemModel?, String>((ref, itemId) async {
  final doc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
  if (!doc.exists) return null;
  return ItemModel.fromMap(doc.data()!, doc.id);
});

// 2. Provider to fetch the reporter's FULL profile from the 'users' collection
final reporterProfileProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
  return doc.data();
});

class ItemDetailScreen extends ConsumerWidget {
  final String itemId;

  const ItemDetailScreen({super.key, required this.itemId});

  // Helper function to show the contact bottom sheet
  void _showContactBottomSheet(BuildContext context, String phone, String name) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
                ),
                const SizedBox(height: 24),
                const Text('Contact Reporter', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Arrange a handover with $name', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                          if (formattedPhone.startsWith('0')) formattedPhone = '6$formattedPhone';
                          
                          final Uri whatsappUrl = Uri.parse('https://wa.me/$formattedPhone');
                          try {
                            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch WhatsApp')));
                          }
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text('WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri phoneUrl = Uri.parse('tel:$phone');
                          try {
                            await launchUrl(phoneUrl);
                          } catch (e) {
                            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open phone dialer')));
                          }
                        },
                        icon: const Icon(Icons.phone, size: 18),
                        label: const Text('Call'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
            child: SizedBox(
              width: double.infinity, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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

                  // LOCATION INFO
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

                  // REPORTER INFO
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
                            final profileState = ref.watch(reporterProfileProvider(item.reportedBy));
                            
                            return profileState.when(
                              loading: () => const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              error: (e, s) => const Text('Unknown User'),
                              data: (userData) {
                                // 1. Strict Name Fix: Prevent email from showing
                                String name = userData?['fullName'] ?? item.reportedByName;
                                if (name.isEmpty || name.contains('@')) {
                                  name = 'Ahmad Adam Danial Bin Ab Rahman'; // Safe fallback for old test items
                                }
                                
                                final matric = userData?['matricNumber'] ?? 'Matric Unknown';
                                final phone = userData?['phoneNumber'] ?? '';

                                return Column(
                                  children: [
                                    // 2. Stacked Layout for Name and Matric Number
                                    Text(
                                      name, 
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      matric, 
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.teal.shade800),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // 3. Submit Claim Button
                                    ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ClaimSubmissionScreen(
                                                item: item,
                                              ),
                                            ),
                                          );
                                        },
                                      icon: const Icon(Icons.handshake),
                                      label: const Text('SUBMIT CLAIM PROCESS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                        backgroundColor: Colors.teal,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                        elevation: 2,
                                      ),
                                    ),
                                    
                                    if (phone.isEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text('Contact info unavailable', style: TextStyle(color: Colors.red.shade300, fontSize: 12, fontStyle: FontStyle.italic)),
                                      )
                                  ],
                                );
                              },
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