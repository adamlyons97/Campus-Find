import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/claim_status_provider.dart';

class MyClaimsScreen extends ConsumerWidget {
  const MyClaimsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('My Claims')),
      body: auth == null
          ? const Center(child: Text('Not signed in'))
          : ref.watch(myClaimsProvider(auth.uid)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (claims) => claims.isEmpty
                    ? const Center(
                        child: Text('You have not claimed any items yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: claims.length,
                        itemBuilder: (_, i) {
                          final c = claims[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: _statusIcon(c.status),
                              title: Text(c.itemTitle ?? 'Item'),
                              subtitle: Text(
                                'Submitted ${DateFormat('d MMM yyyy').format(c.claimedAt)}',
                              ),
                              trailing: Text(
                                c.status.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(c.status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
    );
  }

  Widget _statusIcon(String status) {
    switch (status) {
      case ClaimStatus.approved:
        return const Icon(Icons.check_circle, color: AppTheme.success);
      case ClaimStatus.rejected:
        return const Icon(Icons.cancel, color: AppTheme.danger);
      default:
        return const Icon(Icons.hourglass_top, color: AppTheme.warning);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case ClaimStatus.approved:
        return AppTheme.success;
      case ClaimStatus.rejected:
        return AppTheme.danger;
      default:
        return AppTheme.warning;
    }
  }
}
