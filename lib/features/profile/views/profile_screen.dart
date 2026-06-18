import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Grab the current user directly from Firebase
    final user = FirebaseAuth.instance.currentUser;
    
    // Set up display variables with safe fallbacks
    final email = user?.email ?? 'No email available';
    final displayName = user?.displayName ?? email.split('@')[0];
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Profile Avatar
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
          
          // User Details Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.teal),
                    title: const Text('Student Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(displayName, style: const TextStyle(fontSize: 18, color: Colors.black87)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email, color: Colors.teal),
                    title: const Text('Campus Email', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    subtitle: Text(email, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          // The New Logout Button Location
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
      ),
    );
  }
}