import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../claims/views/claim_submission_screen.dart';
import '../../home/providers/item_list_provider.dart';

class ItemDetailScreen extends ConsumerWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemAsync = ref.watch(itemByIdProvider(itemId));
    final me = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: itemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (item) {
          if (item == null) {
            return const Center(child: Text('This item no longer exists.'));
          }
          final isOwnPost = me?.uid == item.reporterId;
          final isFound = item.type == ItemType.found;
          final canClaim =
              isFound && !isOwnPost && item.status == ItemStatus.active;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: item.imageUrl!,
                    width: double.infinity,
                    height: 260,
                    fit: BoxFit.cover,
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _Pill(
                            text: isFound ? 'FOUND' : 'LOST',
                            color: isFound ? AppTheme.success : AppTheme.danger,
                          ),
                          const SizedBox(width: 8),
                          _Pill(
                            text: item.status.toUpperCase(),
                            color: AppTheme.primary,
                            outlined: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(item.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(item.description,
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 20),
                      _DetailRow(
                          icon: Icons.category_outlined,
                          label: 'Category',
                          value: item.categoryName),
                      _DetailRow(
                          icon: Icons.place_outlined,
                          label: 'Location',
                          value: item.locationSeen.name.isEmpty
                              ? '—'
                              : item.locationSeen.name),
                      if (item.locationSeen.specificDetails.isNotEmpty)
                        _DetailRow(
                            icon: Icons.notes_outlined,
                            label: 'Details',
                            value: item.locationSeen.specificDetails),
                      _DetailRow(
                          icon: Icons.person_outline,
                          label: 'Reported by',
                          value: item.reporterName),
                      _DetailRow(
                          icon: Icons.schedule,
                          label: 'Reported on',
                          value: DateFormat('d MMM yyyy, HH:mm')
                              .format(item.reportedAt)),
                      if (isFound &&
                          (item.finderClaimRequestNotes?.isNotEmpty ?? false))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                                'Handover note: ${item.finderClaimRequestNotes}'),
                          ),
                        ),
                      const SizedBox(height: 24),
                      if (canClaim)
                        FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClaimSubmissionScreen(item: item),
                            ),
                          ),
                          icon: const Icon(Icons.verified_outlined),
                          label: const Text('This is mine — Claim it'),
                        ),
                      if (item.status == ItemStatus.resolved)
                        const _ResolvedBanner(),
                      if (isOwnPost)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'This is your own report.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryLight),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black54)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.outlined = false});
  final String text;
  final Color color;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: outlined ? null : color.withValues(alpha: 0.12),
        border: outlined ? Border.all(color: color) : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}

class _ResolvedBanner extends StatelessWidget {
  const _ResolvedBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.celebration_outlined, color: AppTheme.primary),
          SizedBox(width: 10),
          Expanded(
              child:
                  Text('This item has been reunited with its rightful owner. '
                      'Alhamdulillah.')),
        ],
      ),
    );
  }
}
