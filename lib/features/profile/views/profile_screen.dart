import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../data/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

/// Profile tab: identity header, contribution stats and account actions.
/// Designed fresh for the redesigned CampusFind shell.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    String firstCh(String s) =>
        s.isEmpty ? '' : s.substring(0, 1).toUpperCase();
    if (parts.length == 1) return firstCh(parts.first);
    return firstCh(parts.first) + firstCh(parts.last);
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'security':
        return 'Security Verifier';
      case 'staff':
        return 'Staff';
      default:
        return 'Student';
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sign out')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).signOut();
      if (context.mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load profile.\n$e',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted)),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              const Align(alignment: Alignment.centerRight, child: BrandMark()),
              const SizedBox(height: 8),
              const SectionLabel('My Account'),
              const SizedBox(height: 4),
              const Text(
                'Profile',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              _IdentityCard(
                  user: user,
                  initials: _initials(user.name),
                  roleLabel: _roleLabel(user.role)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: user.totalItemsReported.toString(),
                      label: 'Items Reported',
                      icon: Icons.upload_file_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StatCard(
                      value: user.totalItemsReunited.toString(),
                      label: 'Items Reunited',
                      icon: Icons.volunteer_activism_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Activity', color: AppTheme.textMuted),
              const SizedBox(height: 12),
              _MenuTile(
                icon: Icons.inventory_2_outlined,
                title: 'My Reports',
                subtitle: 'Items you have posted',
                onTap: () => context.push('/my-items'),
              ),
              _MenuTile(
                icon: Icons.assignment_turned_in_outlined,
                title: 'My Claims',
                subtitle: 'Claims you have submitted',
                onTap: () => context.push('/my-claims'),
              ),
              _MenuTile(
                icon: Icons.auto_awesome_outlined,
                title: 'AI Smart Search',
                subtitle: 'Describe an item to find matches',
                onTap: () => context.push('/search'),
              ),
              if (user.isVerifier)
                _MenuTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Verifier Dashboard',
                  subtitle: 'Review and approve pending claims',
                  highlight: true,
                  onTap: () => context.push('/verify'),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _signOut(context, ref),
                icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
                label: const Text('Sign out',
                    style: TextStyle(
                        color: AppTheme.danger, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  side: const BorderSide(color: Color(0xFFF3C9C9)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.user,
    required this.initials,
    required this.roleLabel,
  });
  final UserModel user;
  final String initials;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.tintBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? 'CampusFind User' : user.name,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  style:
                      const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlight = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: highlight ? AppTheme.tintBlue : AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: highlight
                      ? AppTheme.primary.withValues(alpha: 0.25)
                      : AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: highlight ? AppTheme.primary : AppTheme.tintBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: highlight ? Colors.white : AppTheme.primary,
                      size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
