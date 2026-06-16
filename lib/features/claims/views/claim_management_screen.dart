import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme.dart';
import '../../../data/models/claim_model.dart';
import '../providers/claim_status_provider.dart';

/// Role-based dashboard where security/admin verifiers review pending
/// claims and approve or reject them (Feature 4 — Secure Claim System).
class ClaimManagementScreen extends ConsumerWidget {
  const ClaimManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingClaimsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify Claims')),
      body: pending.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (claims) {
          if (claims.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No pending claims. All caught up.'),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: claims.length,
            itemBuilder: (_, i) => _ClaimReviewCard(claim: claims[i]),
          );
        },
      ),
    );
  }
}

class _ClaimReviewCard extends ConsumerWidget {
  const _ClaimReviewCard({required this.claim});
  final ClaimModel claim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(claimControllerProvider);
    final busy = state.isLoading;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2_outlined,
                    color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    claim.itemTitle ?? 'Item',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat('d MMM, HH:mm').format(claim.claimedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Claimant: ${claim.claimantName ?? claim.claimantId}',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E5E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stated proof of ownership:',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(claim.proofOfOwnership),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(claimControllerProvider.notifier)
                            .reject(claim.id),
                    icon: const Icon(Icons.close, color: AppTheme.danger),
                    label: const Text('Reject',
                        style: TextStyle(color: AppTheme.danger)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.danger),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => ref
                            .read(claimControllerProvider.notifier)
                            .approve(
                              claimId: claim.id,
                              itemId: claim.itemId,
                            ),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
