import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/providers/auth_provider.dart';

// Fetches the synchronized user data from Firestore
final userProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return doc.exists ? doc.data() : null;
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final profileState = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
        error: (err, stack) => Center(child: Text('Error loading profile: $err')),
        data: (userData) {
          // Fallback logic in case they created an account before we added the database sync
          final email = user?.email ?? 'No email available';
          final authName = user?.displayName ?? '';
          
          final fullName = userData?['fullName'] ?? (authName.isNotEmpty ? authName : 'Ahmad Adam Danial Bin Ab Rahman');
          final matricNumber = userData?['matricNumber'] ?? '2319525';
          
          final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              // Smart Avatar
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Synchronized Details Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Colors.teal),
                        title: const Text('Full Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        subtitle: Text(fullName, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.badge, color: Colors.teal),
                        title: const Text('Matric Number', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        subtitle: Text(matricNumber, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.teal),
                        title: const Text('University Email', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        subtitle: Text(email, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Logout Button
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('SECURE LOGOUT', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}