import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../../../data/models/item_model.dart';
import '../../home/providers/item_list_provider.dart';
import '../../home/widgets/item_card.dart';

/// Browse tab: searchable, filterable catalogue of every item.
class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  static const _chips = [
    ('all', 'ALL'),
    ('lost', 'LOST'),
    ('found', 'FOUND'),
    ('returned', 'RETURNED'),
  ];

  List<ItemModel> _apply(List<ItemModel> items, String filter, String query) {
    Iterable<ItemModel> out = items;
    switch (filter) {
      case 'lost':
        out = out.where(
            (i) => i.status == ItemStatus.active && i.type == ItemType.lost);
        break;
      case 'found':
        out = out.where(
            (i) => i.status == ItemStatus.active && i.type == ItemType.found);
        break;
      case 'returned':
        out = out.where((i) => i.status == ItemStatus.resolved);
        break;
      case 'all':
      default:
        out = out.where((i) => i.status == ItemStatus.active);
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      out = out.where((i) =>
          i.title.toLowerCase().contains(q) ||
          i.categoryName.toLowerCase().contains(q) ||
          i.locationSeen.name.toLowerCase().contains(q) ||
          i.description.toLowerCase().contains(q));
    }
    return out.toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allItems = ref.watch(allItemsProvider);
    final filter = ref.watch(browseFilterProvider);
    final query = ref.watch(browseQueryProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Align(
                    alignment: Alignment.centerRight, child: BrandMark()),
                const SizedBox(height: 8),
                allItems.when(
                  loading: () => const SectionLabel('Loading entries'),
                  error: (_, __) => const SectionLabel('Catalogue'),
                  data: (items) => SectionLabel(
                      '${_apply(items, 'all', '').length} active entries'),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Browse your items',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  onChanged: (v) =>
                      ref.read(browseQueryProvider.notifier).state = v,
                  decoration: const InputDecoration(
                    hintText: 'Search parameters...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final c in _chips) ...[
                        _FilterChip(
                          label: c.$2,
                          selected: filter == c.$1,
                          onTap: () => ref
                              .read(browseFilterProvider.notifier)
                              .state = c.$1,
                        ),
                        const SizedBox(width: 10),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
          Expanded(
            child: allItems.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load items.\n$e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textMuted)),
                ),
              ),
              data: (items) {
                final filtered = _apply(items, filter, query);
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No items match your search.',
                        style: TextStyle(color: AppTheme.textMuted)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => ItemCard(
                    item: filtered[i],
                    onTap: () => context.push('/item/${filtered[i].id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
