import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart'; // Used to format the dates cleanly

import '../../auth/providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../../../data/models/item_model.dart';

class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2, // Two tabs: Lost and Found
      child: Scaffold(
        appBar: AppBar(
          title: const Text('CampusFeed', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber, // A nice contrast color for the active tab
            indicatorWeight: 3,
            tabs: [
              Tab(icon: Icon(Icons.search_off), text: 'LOST ITEMS'),
              Tab(icon: Icon(Icons.check_circle_outline), text: 'FOUND ITEMS'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_active),
              tooltip: 'My Posts & Alerts',
              onPressed: () {
                context.push('/my-posts');
              },
            ),
            IconButton(
              icon: const Icon(Icons.account_circle, size: 28),
              tooltip: 'My Profile',
              onPressed: () {
                context.push('/profile');
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        
        // The body switches between the two streams based on the active tab
        body: TabBarView(
          children: [
            _buildItemFeed(ref, lostItemsStreamProvider),
            _buildItemFeed(ref, foundItemsStreamProvider),
          ],
        ),

        // The button to report a new item
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Triggers smooth path transitions
            context.push('/create-post');
          },
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_a_photo),
          label: const Text('REPORT ITEM'),
        ),
      ),
    );
  }

  /// A reusable widget builder that reads a Riverpod stream and turns it into a list of cards
  Widget _buildItemFeed(WidgetRef ref, AutoDisposeStreamProvider<List<ItemModel>> provider) {
    final itemStream = ref.watch(provider);

    return itemStream.when(
      // 1. Loading State
      loading: () => const Center(child: CircularProgressIndicator(color: Colors.teal)),
      
      // 2. Error State
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Error loading feed: $error', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      ),
      
      // 3. Success Data State
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text('No active items in this category.', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            // We pass 'context' here so the card knows how to navigate!
            return _buildItemCard(context, item);
          },
        );
      },
    );
  }

  /// The visual design for a single Lost/Found item card
  // UPDATED: Added BuildContext as a parameter
  Widget _buildItemCard(BuildContext context, ItemModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // We wrap the padding in an InkWell to make the whole card tapped!
      child: InkWell(
        borderRadius: BorderRadius.circular(12), // Keeps the ripple inside the rounded corners
        onTap: () {
          // Push to the new Detail Screen with this specific item's ID
          context.push('/item-detail/${item.itemId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.categoryName,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.teal),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.locationSeen.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    // Formats the raw timestamp into a readable date (e.g., Oct 12, 2025)
                    DateFormat.yMMMd().format(item.reportedAt),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}