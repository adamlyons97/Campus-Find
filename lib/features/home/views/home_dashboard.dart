import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/item_list_provider.dart';
import '../widgets/item_card.dart';

/// Home tab: a welcome header, the two report shortcuts, a browse-catalogue
/// card and the most recently reported items.
class HomeDashboard extends ConsumerWidget {
  const HomeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider).valueOrNull;
    final allItems = ref.watch(allItemsProvider);
    final firstName = (profile?.name ?? 'there').split(' ').first;

    final activeItems = allItems.valueOrNull
            ?.where((i) => i.status == ItemStatus.active)
            .toList() ??
        const [];
    final recent = activeItems.take(5).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Align(alignment: Alignment.centerRight, child: BrandMark()),
          const SizedBox(height: 12),
          SectionLabel('Welcome, $firstName'),
          const SizedBox(height: 4),
          const Text(
            'CampusFind',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ReportCard(
                  color: AppTheme.lost,
                  icon: Icons.warning_amber_rounded,
                  title: 'Report\nLost Item',
                  onTap: () => context.push('/create?type=${ItemType.lost}'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ReportCard(
                  color: AppTheme.found,
                  icon: Icons.check_rounded,
                  title: 'Report\nFound Item',
                  onTap: () => context.push('/create?type=${ItemType.found}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BrowseCatalogCard(
            count: activeItems.length,
            onTap: () => context.go('/browse'),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const SectionLabel('Recently Reported', color: AppTheme.textMuted),
              const SizedBox(width: 10),
              const Expanded(child: Divider(color: AppTheme.cardBorder)),
            ],
          ),
          const SizedBox(height: 14),
          allItems.when(
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Text('Could not load items.\n$e',
                  style: const TextStyle(color: AppTheme.textMuted)),
            ),
            data: (_) {
              if (recent.isEmpty) {
                return const _EmptyHint();
              }
              return Column(
                children: [
                  for (final item in recent) ...[
                    ItemCard(
                      item: item,
                      onTap: () => context.push('/item/${item.id}'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseCatalogCard extends StatelessWidget {
  const _BrowseCatalogCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.tintBlue,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse catalog',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SectionLabel('$count active entries'),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: const Column(
        children: [
          Icon(Icons.inbox_outlined, size: 44, color: AppTheme.textMuted),
          SizedBox(height: 10),
          Text('No active items yet.',
              style: TextStyle(color: AppTheme.textMuted)),
          Text('Be the first to report a lost or found item.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}
