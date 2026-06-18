import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to show a popup dialog and update Firebase directly
  Future<void> _editNameDialog() async {
    final currentName = _auth.currentUser?.displayName ?? '';
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Student Name'),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g., Ahmad Adam Danial', // A helpful hint for the user
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );

    // If the user typed a new name, save it to the Google Cloud!
    if (newName != null && newName.isNotEmpty && newName != currentName) {
      await _auth.currentUser?.updateDisplayName(newName);
      await _auth.currentUser?.reload(); // Forces Firebase to fetch the newest data
      setState(() {}); // Refreshes the UI instantly
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.teal),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'No email available';

    // Smarter logic to ensure we ALWAYS have a name to display
    String displayName = '';
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      displayName = user.displayName!;
    } else {
      displayName = 'Tap to set your name'; // Better fallback text
    }

    // Extract the first letter for the Smart Avatar (defaults to 'U' for User if empty)
    final initial = (user?.displayName != null && user!.displayName!.trim().isNotEmpty) 
        ? user.displayName![0].toUpperCase() 
        : 'U';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // The Smart Avatar
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.teal.shade100,
                  child: Text(
                    initial,
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                // A tiny camera icon to hint that photo uploads might come later!
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // User Details Card with Edit Button
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
                    subtitle: Text(
                      displayName, 
                      style: TextStyle(
                        fontSize: 18, 
                        color: displayName == 'Tap to set your name' ? Colors.grey : Colors.black87,
                        fontStyle: displayName == 'Tap to set your name' ? FontStyle.italic : FontStyle.normal,
                      )
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal),
                      onPressed: _editNameDialog, // Triggers the popup!
                    ),
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
      ),
    );
  }
}