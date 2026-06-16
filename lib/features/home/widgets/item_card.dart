import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../../../data/models/item_model.dart';

/// A single lost/found item row, matching the redesigned catalogue style:
/// rounded tinted card, thumbnail on the left, title + location/time in the
/// middle and a coloured status pill on the right.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item, this.onTap});

  final ItemModel item;
  final VoidCallback? onTap;

  String get _badgeLabel {
    if (item.status == ItemStatus.resolved) return 'RETURNED';
    return item.type == ItemType.found ? 'FOUND' : 'LOST';
  }

  String get _badgeKey {
    if (item.status == ItemStatus.resolved) return 'resolved';
    return item.type == ItemType.found ? 'found' : 'lost';
  }

  IconData get _categoryIcon {
    final c = item.categoryName.toLowerCase();
    if (c.contains('electron')) return Icons.devices_other_outlined;
    if (c.contains('card') || c.contains('document')) {
      return Icons.badge_outlined;
    }
    if (c.contains('key')) return Icons.vpn_key_outlined;
    if (c.contains('cloth') || c.contains('apparel')) {
      return Icons.checkroom_outlined;
    }
    if (c.contains('bottle') || c.contains('drink')) {
      return Icons.local_drink_outlined;
    }
    if (c.contains('bag') || c.contains('wallet')) {
      return Icons.work_outline;
    }
    if (c.contains('cash') || c.contains('money')) {
      return Icons.payments_outlined;
    }
    return Icons.inventory_2_outlined;
  }

  String _relativeTime(DateTime t) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, now.day)
        .difference(DateTime(t.year, t.month, t.day))
        .inDays;
    if (d <= 0) return 'Today';
    if (d == 1) return 'Yesterday';
    if (d < 7) return '$d days ago';
    return DateFormat('d MMM').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final location =
        item.locationSeen.name.isEmpty ? 'Campus' : item.locationSeen.name;

    return Material(
      color: AppTheme.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _Thumb(item: item, fallbackIcon: _categoryIcon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$location  ·  ${_relativeTime(item.reportedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _Badge(label: _badgeLabel, badgeKey: _badgeKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.item, required this.fallbackIcon});
  final ItemModel item;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    const size = 54.0;
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CachedNetworkImage(
          imageUrl: item.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => const _IconBox(icon: Icons.image_outlined),
          errorWidget: (_, __, ___) =>
              _IconBox(icon: fallbackIcon),
        ),
      );
    }
    return _IconBox(icon: fallbackIcon);
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.tintBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppTheme.primary, size: 26),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.badgeKey});
  final String label;
  final String badgeKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.badgeBg(badgeKey),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.badgeFg(badgeKey),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
