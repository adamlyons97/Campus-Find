import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../data/models/campus_item.dart';
import '../../../data/models/item_claim.dart';
import '../../../data/models/profile.dart';
import '../providers/campus_controller.dart';
import '../widgets/location_map_picker.dart';

const _primaryBlue = Color(0xFF2563EB);
const _softBlue = Color(0xFFEFF6FF);
const _dangerRed = Color(0xFFEF4444);
const _ink = Color(0xFF0F172A);
const _mutedInk = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);
const _page = Color(0xFFF8FAFC);

const _categories = [
  'Bag',
  'Book',
  'Bottle',
  'Electronics',
  'ID / Card',
  'Keys',
  'Wallet',
  'Other',
];

String? _requiredValue(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Required';
  }
  return null;
}

bool _isValidEmail(String value) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());
}

bool _isValidPhone(String value) {
  final compact = value.trim().replaceAll(RegExp(r'[\s().-]'), '');
  return RegExp(r'^\+?\d{7,15}$').hasMatch(compact);
}

String? _emailValidator(String? value) {
  final requiredMessage = _requiredValue(value);
  if (requiredMessage != null) {
    return requiredMessage;
  }
  if (!_isValidEmail(value!)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? _phoneValidator(String? value) {
  final requiredMessage = _requiredValue(value);
  if (requiredMessage != null) {
    return requiredMessage;
  }
  if (!_isValidPhone(value!)) {
    return 'Enter a valid phone number';
  }
  return null;
}

String? _contactValidator(String? value) {
  final requiredMessage = _requiredValue(value);
  if (requiredMessage != null) {
    return requiredMessage;
  }
  final contact = value!.trim();
  if (!_isValidEmail(contact) && !_isValidPhone(contact)) {
    return 'Enter a valid email or phone number';
  }
  return null;
}

void _showAuthError(BuildContext context, Object error) {
  var message = 'Authentication failed. Please try again.';

  if (error is FirebaseAuthException) {
    message = switch (error.code) {
      'email-already-in-use' => 'An account already uses this email address.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Incorrect email address or password.',
      'invalid-email' => 'Enter a valid email address.',
      'operation-not-allowed' =>
        'Enable Email/Password in Firebase Authentication sign-in methods.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'weak-password' => 'Use a stronger password with at least 6 characters.',
      'network-request-failed' =>
        'Check your internet connection and try again.',
      _ => error.message ?? message,
    };
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class CampusHome extends StatefulWidget {
  const CampusHome({super.key, required this.controller});

  final CampusController controller;

  @override
  State<CampusHome> createState() => _CampusHomeState();
}

class _CampusHomeState extends State<CampusHome> {
  bool _isSignedIn = false;
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _isSignedIn =
        Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        if (controller.isLoading) {
          return const _LoadingScaffold();
        }

        if (controller.errorMessage != null) {
          return _ErrorScaffold(
            message: controller.errorMessage!,
            onRetry: controller.load,
          );
        }

        if (!_isSignedIn) {
          return _LoginPage(
            profile: controller.profile,
            onSignIn: (profile, password) async {
              if (Firebase.apps.isNotEmpty) {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: profile.email,
                  password: password,
                );
                await controller.load();
              } else {
                await controller.saveProfile(profile);
              }
              if (mounted) {
                setState(() => _isSignedIn = true);
              }
            },
            onSignUp: (profile, password) async {
              if (Firebase.apps.isNotEmpty) {
                final credential = await FirebaseAuth.instance
                    .createUserWithEmailAndPassword(
                      email: profile.email,
                      password: password,
                    );
                await credential.user?.updateDisplayName(profile.name);
              }
              await controller.saveProfile(profile);
              if (mounted) {
                setState(() => _isSignedIn = true);
              }
            },
          );
        }

        final pages = [
          _BrowsePage(controller: controller),
          _HomePage(
            controller: controller,
            onBrowse: () => setState(() => _selectedIndex = 0),
          ),
          _ProfilePage(
            controller: controller,
            onLogout: () async {
              if (Firebase.apps.isNotEmpty) {
                await FirebaseAuth.instance.signOut();
              }
              if (!mounted) {
                return;
              }
              setState(() {
                _selectedIndex = 1;
                _isSignedIn = false;
              });
            },
          ),
        ];

        return Scaffold(
          backgroundColor: _page,
          body: SafeArea(child: pages[_selectedIndex]),
          bottomNavigationBar: _BottomNav(
            selectedIndex: _selectedIndex,
            onSelected: (value) => setState(() => _selectedIndex = value),
          ),
        );
      },
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _page,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 44, color: _dangerRed),
              const SizedBox(height: 14),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoginPage extends StatefulWidget {
  const _LoginPage({
    required this.profile,
    required this.onSignIn,
    required this.onSignUp,
  });

  final Profile profile;
  final Future<void> Function(Profile profile, String password) onSignIn;
  final Future<void> Function(Profile profile, String password) onSignUp;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: _primaryBlue,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryBlue.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to your account to continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _mutedInk, fontSize: 12),
                ),
                const SizedBox(height: 26),
                const _FieldLabel('EMAIL'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Email Address'),
                  validator: _emailValidator,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('PASSWORD'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'Password'),
                  validator: _requiredValue,
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  child: _isSigningIn
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign In'),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: _mutedInk, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: _isSigningIn ? null : _openSignUp,
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSigningIn = true);
    final email = _emailController.text.trim();
    final name = _nameFromEmail(email);
    try {
      await widget.onSignIn(
        widget.profile.copyWith(
          name: widget.profile.name == Profile.fallback.name
              ? name
              : widget.profile.name,
          email: email,
        ),
        _passwordController.text,
      );
    } catch (error) {
      if (mounted) {
        _showAuthError(context, error);
        setState(() => _isSigningIn = false);
      }
    }
  }

  String _nameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    if (prefix.isEmpty) {
      return 'Harpreet';
    }
    return prefix[0].toUpperCase() + prefix.substring(1);
  }

  Future<void> _openSignUp() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _SignUpPage(profile: widget.profile, onSignUp: widget.onSignUp),
      ),
    );
  }
}

class _SignUpPage extends StatefulWidget {
  const _SignUpPage({required this.profile, required this.onSignUp});

  final Profile profile;
  final Future<void> Function(Profile profile, String password) onSignUp;

  @override
  State<_SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<_SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            children: [
              const SizedBox(height: 18),
              Row(
                children: [
                  _BackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Create Account',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: _ink, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Set up your CampusFind profile to start reporting items.',
                style: TextStyle(color: _mutedInk, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('FULL NAME'),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: _requiredValue,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('EMAIL'),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _emailValidator,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('PHONE'),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: _phoneValidator,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('PASSWORD'),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                validator: _passwordValidator,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('CONFIRM PASSWORD'),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: _confirmPasswordValidator,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _isCreating ? null : _createAccount,
                icon: _isCreating
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.length < 6) {
      return 'Use at least 6 characters';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _createAccount() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isCreating = true);
    try {
      await widget.onSignUp(
        Profile(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          campus: Profile.fallback.campus,
        ),
        _passwordController.text,
      );
    } catch (error) {
      if (mounted) {
        _showAuthError(context, error);
        setState(() => _isCreating = false);
      }
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.controller, required this.onBrowse});

  final CampusController controller;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final recentItems = controller.allItems.take(4).toList();
    final firstName = controller.profile.name.split(' ').first.toUpperCase();

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          _Eyebrow('WELCOME, $firstName'),
          const SizedBox(height: 2),
          Text(
            'CampusFind',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _ReportActionCard(
                  color: _dangerRed,
                  icon: Icons.warning_amber_rounded,
                  title: 'Report\nLost Item',
                  onTap: () =>
                      _openReportPage(context, controller, ItemStatus.lost),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ReportActionCard(
                  color: const Color(0xFF3B82F6),
                  icon: Icons.check,
                  title: 'Report\nFound Item',
                  onTap: () =>
                      _openReportPage(context, controller, ItemStatus.found),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BrowseCatalogCard(
            count: controller.allItems.length,
            onTap: onBrowse,
          ),
          const SizedBox(height: 22),
          const _Eyebrow('RECENTLY REPORTED'),
          const SizedBox(height: 10),
          if (recentItems.isEmpty)
            const _EmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: 'No reports yet',
              message: 'The first lost or found item will appear here.',
            )
          else
            for (final item in recentItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItemTile(
                  item: item,
                  onTap: () => _openItemDetails(context, controller, item),
                ),
              ),
        ],
      ),
    );
  }
}

class _ReportActionCard extends StatelessWidget {
  const _ReportActionCard({
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          height: 92,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
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
      color: _softBlue,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Browse catalog',
                      style: TextStyle(
                        color: _primaryBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count active entries',
                      style: const TextStyle(
                        color: _primaryBlue,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: _primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowsePage extends StatefulWidget {
  const _BrowsePage({required this.controller});

  final CampusController controller;

  @override
  State<_BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<_BrowsePage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.controller.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        _Eyebrow('${controller.visibleItems.length} ACTIVE ENTRIES'),
        const SizedBox(height: 2),
        Text(
          'Browse your items',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onChanged: controller.setQuery,
          decoration: InputDecoration(
            hintText: 'Search parameters...',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: controller.query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      controller.setQuery('');
                    },
                    icon: const Icon(Icons.close, size: 18),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        _FilterChips(controller: controller),
        const SizedBox(height: 16),
        if (controller.visibleItems.isEmpty)
          const _EmptyPanel(
            icon: Icons.search_off,
            title: 'No matching items',
            message: 'Try a different search term or filter.',
          )
        else
          for (final item in controller.visibleItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ItemTile(
                item: item,
                onTap: () => _openItemDetails(context, controller, item),
              ),
            ),
      ],
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.controller});

  final CampusController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in ItemFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: controller.filter == filter,
                showCheckmark: false,
                label: Text(
                  filter == ItemFilter.claimed ? 'Resolved' : filter.label,
                ),
                onSelected: (_) => controller.setFilter(filter),
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.onTap});

  final CampusItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ItemIcon(category: item.category, imageData: item.imageData),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.location}  -  ${item.category}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _mutedInk, fontSize: 11),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Today',
                      style: TextStyle(color: _mutedInk, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(item: item),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemIcon extends StatelessWidget {
  const _ItemIcon({required this.category, this.imageData});

  final String category;
  final String? imageData;

  @override
  Widget build(BuildContext context) {
    final icon = switch (category) {
      'Bottle' => Icons.water_drop,
      'Book' => Icons.menu_book,
      'Electronics' => Icons.headphones,
      'ID / Card' => Icons.badge,
      'Keys' => Icons.key,
      'Wallet' => Icons.account_balance_wallet,
      'Bag' => Icons.backpack,
      _ => Icons.inventory_2,
    };

    final selectedImageData = imageData;

    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: _page,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      clipBehavior: Clip.antiAlias,
      child: selectedImageData == null
          ? Icon(icon, color: _primaryBlue.withValues(alpha: 0.75), size: 22)
          : Image.memory(base64Decode(selectedImageData), fit: BoxFit.cover),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.item});

  final CampusItem item;

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      ItemStatus.lost => _dangerRed,
      ItemStatus.found => const Color(0xFF3B82F6),
      ItemStatus.claimed => const Color(0xFF7C3AED),
    };

    final label = item.displayStatusLabel.toUpperCase();

    return Container(
      constraints: const BoxConstraints(minWidth: 48),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.controller, required this.onLogout});

  final CampusController controller;
  final Future<void> Function() onLogout;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final profile = widget.controller.profile;
    _nameController = TextEditingController(text: profile.name);
    _emailController = TextEditingController(text: profile.email);
    _phoneController = TextEditingController(text: profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const _Eyebrow('ACCOUNT'),
        Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: _ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Form(
          key: _formKey,
          child: _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('NAME'),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  validator: _requiredValue,
                ),
                const SizedBox(height: 12),
                const _FieldLabel('EMAIL'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 12),
                const _FieldLabel('PHONE'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _phoneValidator,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Profile'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async => widget.onLogout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _ClaimsReview(controller: widget.controller),
      ],
    );
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    await widget.controller.saveProfile(
      Profile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        campus: widget.controller.profile.campus,
      ),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Profile saved')));
  }
}

class _ClaimsReview extends StatelessWidget {
  const _ClaimsReview({required this.controller});

  final CampusController controller;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('CLAIMS REVIEW'),
          const SizedBox(height: 10),
          if (controller.claims.isEmpty)
            const Text(
              'Claims submitted from item details will appear here.',
              style: TextStyle(color: _mutedInk),
            )
          else
            for (final claim in controller.claims)
              _ClaimRow(controller: controller, claim: claim),
        ],
      ),
    );
  }
}

class _ClaimRow extends StatelessWidget {
  const _ClaimRow({required this.controller, required this.claim});

  final CampusController controller;
  final ItemClaim claim;

  @override
  Widget build(BuildContext context) {
    final item = controller.findItem(claim.itemId);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item?.title ?? 'Deleted item',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            '${claim.claimantName} - ${claim.contact}',
            style: const TextStyle(color: _mutedInk, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: claim.status == ClaimStatus.approved
                    ? null
                    : () => controller.updateClaimStatus(
                        claim,
                        ClaimStatus.approved,
                      ),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
              ),
              OutlinedButton.icon(
                onPressed: claim.status == ClaimStatus.rejected
                    ? null
                    : () => controller.updateClaimStatus(
                        claim,
                        ClaimStatus.rejected,
                      ),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
              ),
              if (item != null)
                OutlinedButton.icon(
                  onPressed: () =>
                      controller.updateItemStatus(item, ItemStatus.claimed),
                  icon: const Icon(Icons.verified, size: 16),
                  label: Text(item.resolvedLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportPage extends StatefulWidget {
  const _ReportPage({required this.controller, required this.initialStatus});

  final CampusController controller;
  final ItemStatus initialStatus;

  @override
  State<_ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<_ReportPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late ItemStatus _status;
  String? _category;
  String? _imageData;
  double? _latitude;
  double? _longitude;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _locationController = TextEditingController();
    _nameController = TextEditingController();
    _contactController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _status == ItemStatus.lost
        ? 'Report Lost Item'
        : 'Report Found Item';

    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Row(
                children: [
                  _BackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _UploadBox(
                status: _status,
                imageData: _imageData,
                onTap: _pickImage,
                onRemove: _imageData == null
                    ? null
                    : () => setState(() => _imageData = null),
              ),
              const SizedBox(height: 18),
              const _FieldLabel('ITEM HEADER NAME'),
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Matte blue water bottle',
                ),
                validator: _requiredValue,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('CATEGORY'),
              DropdownButtonFormField<String>(
                initialValue: _category,
                hint: const Text('Select category...'),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
                validator: _requiredValue,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('REPORT TYPE'),
              SegmentedButton<ItemStatus>(
                segments: const [
                  ButtonSegment(
                    value: ItemStatus.lost,
                    label: Text('Lost'),
                    icon: Icon(Icons.warning_amber),
                  ),
                  ButtonSegment(
                    value: ItemStatus.found,
                    label: Text('Found'),
                    icon: Icon(Icons.check),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (value) {
                  setState(() => _status = value.first);
                },
              ),
              const SizedBox(height: 14),
              const _FieldLabel('DESCRIPTION'),
              TextFormField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText:
                      'Provide distinct colors, features, or identification properties...',
                ),
                validator: _requiredValue,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('LOCATION CONTEXT'),
              TextFormField(
                controller: _locationController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'e.g. Block B Exam Hall',
                ),
                validator: _requiredValue,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('TAG LOCATION ON MAP'),
              LocationMapPicker(
                latitude: _latitude,
                longitude: _longitude,
                onLocationChanged: (location) {
                  setState(() {
                    _latitude = location?.latitude;
                    _longitude = location?.longitude;
                  });
                },
              ),
              const SizedBox(height: 14),
              const _FieldLabel('CONTACT NAME'),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                validator: _requiredValue,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('CONTACT DETAIL'),
              TextFormField(
                controller: _contactController,
                textInputAction: TextInputAction.done,
                validator: _contactValidator,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: const Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    await widget.controller.createItem(
      title: _titleController.text,
      description: _descriptionController.text,
      category: _category!,
      location: _locationController.text,
      latitude: _latitude,
      longitude: _longitude,
      status: _status,
      reporterName: _nameController.text,
      contact: _contactController.text,
      imageData: _imageData,
    );

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item report saved')));
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 78,
      );
      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      setState(() => _imageData = base64Encode(bytes));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not select image: $error')));
    }
  }
}

class _UploadBox extends StatelessWidget {
  const _UploadBox({
    required this.status,
    required this.imageData,
    required this.onTap,
    required this.onRemove,
  });

  final ItemStatus status;
  final String? imageData;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final selectedImageData = imageData;
    final content = selectedImageData == null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == ItemStatus.lost
                    ? Icons.image_search
                    : Icons.add_photo_alternate,
                color: _primaryBlue,
                size: 20,
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload Item Photo',
                style: TextStyle(
                  color: _primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        : Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  base64Decode(selectedImageData),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton.filled(
                  tooltip: 'Remove image',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close),
                ),
              ),
              const Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Text(
                        'Tap to change photo',
                        style: TextStyle(
                          color: _primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedBorderPainter(color: _primaryBlue),
          child: SizedBox(
            height: selectedImageData == null ? 104 : 150,
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ItemDetailsPage extends StatelessWidget {
  const _ItemDetailsPage({required this.controller, required this.itemId});

  final CampusController controller;
  final int itemId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final item = controller.findItem(itemId);
        if (item == null) {
          return Scaffold(
            backgroundColor: _page,
            appBar: AppBar(title: const Text('Item details')),
            body: const Center(child: Text('This item was removed.')),
          );
        }

        final claims = controller.claimsForItem(itemId);
        final isOwner = controller.isItemOwner(item);
        final canClaim = controller.canClaimItem(item);

        return Scaffold(
          backgroundColor: _page,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Row(
                  children: [
                    _BackButton(onPressed: () => Navigator.of(context).pop()),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Item Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        tooltip: 'Delete',
                        onPressed: () =>
                            _confirmDelete(context, controller, item),
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _ItemIcon(
                            category: item.category,
                            imageData: item.imageData,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.location,
                                  style: const TextStyle(color: _mutedInk),
                                ),
                              ],
                            ),
                          ),
                          _StatusPill(item: item),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (item.imageData != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            base64Decode(item.imageData!),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(item.description),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(icon: Icons.category, label: item.category),
                          _InfoPill(
                            icon: Icons.person,
                            label: item.reporterName,
                          ),
                          _InfoPill(icon: Icons.phone, label: item.contact),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _Eyebrow('TAGGED LOCATION'),
                      const SizedBox(height: 10),
                      TaggedLocationMap(
                        latitude: item.latitude,
                        longitude: item.longitude,
                        locationLabel: item.location,
                      ),
                    ],
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(height: 12),
                  _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Eyebrow('UPDATE STATUS'),
                        const SizedBox(height: 10),
                        if (item.status == ItemStatus.claimed)
                          Text(
                            'This item is marked as ${item.resolvedLabel.toLowerCase()}.',
                            style: const TextStyle(color: _mutedInk),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () =>
                                _resolveItem(context, controller, item),
                            icon: const Icon(Icons.verified, size: 16),
                            label: Text('Mark as ${item.resolvedLabel}'),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(child: _Eyebrow('CLAIMS')),
                    if (canClaim)
                      TextButton.icon(
                        onPressed: () =>
                            _showClaimForm(context, controller, item),
                        icon: const Icon(Icons.assignment_add, size: 16),
                        label: const Text('Claim'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (claims.isEmpty)
                  _EmptyPanel(
                    icon: Icons.assignment_outlined,
                    title: isOwner
                        ? 'No claims for this item'
                        : 'No claim submitted',
                    message: isOwner
                        ? 'Another student can submit a claim from this screen.'
                        : 'Use the Claim button to submit ownership details.',
                  )
                else
                  for (final claim in claims)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ClaimDetailCard(
                        controller: controller,
                        claim: claim,
                      ),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CampusController controller,
    CampusItem item,
  ) async {
    final itemId = item.id;
    if (itemId == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('Delete "${item.title}" and its claims?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.delete),
            label: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !context.mounted) {
      return;
    }

    try {
      await controller.deleteItem(itemId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to delete this item. Check that Firestore rules are published.',
            ),
          ),
        );
      }
      return;
    }
    if (!context.mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item deleted')));
  }

  Future<void> _resolveItem(
    BuildContext context,
    CampusController controller,
    CampusItem item,
  ) async {
    try {
      await controller.updateItemStatus(item, ItemStatus.claimed);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to update status. Check that Firestore rules are published.',
            ),
          ),
        );
      }
    }
  }
}

class _ClaimDetailCard extends StatelessWidget {
  const _ClaimDetailCard({required this.controller, required this.claim});

  final CampusController controller;
  final ItemClaim claim;

  @override
  Widget build(BuildContext context) {
    final item = controller.findItem(claim.itemId);
    final canReview = item != null && controller.isItemOwner(item);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            claim.claimantName,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            claim.contact,
            style: const TextStyle(color: _mutedInk, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(claim.message),
          const SizedBox(height: 10),
          Row(
            children: [
              _ClaimStatusPill(status: claim.status),
              const Spacer(),
              if (canReview) ...[
                IconButton(
                  tooltip: 'Approve',
                  onPressed: claim.status == ClaimStatus.approved
                      ? null
                      : () => controller.updateClaimStatus(
                          claim,
                          ClaimStatus.approved,
                        ),
                  icon: const Icon(Icons.check_circle_outline),
                ),
                IconButton(
                  tooltip: 'Reject',
                  onPressed: claim.status == ClaimStatus.rejected
                      ? null
                      : () => controller.updateClaimStatus(
                          claim,
                          ClaimStatus.rejected,
                        ),
                  icon: const Icon(Icons.cancel_outlined),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ClaimStatusPill extends StatelessWidget {
  const _ClaimStatusPill({required this.status});

  final ClaimStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ClaimStatus.pending => const Color(0xFFEA580C),
      ClaimStatus.approved => _primaryBlue,
      ClaimStatus.rejected => _dangerRed,
    };

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ClaimFormSheet extends StatefulWidget {
  const _ClaimFormSheet({required this.controller, required this.item});

  final CampusController controller;
  final CampusItem item;

  @override
  State<_ClaimFormSheet> createState() => _ClaimFormSheetState();
}

class _ClaimFormSheetState extends State<_ClaimFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _contactController;
  late final TextEditingController _messageController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _contactController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: 18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claim ${widget.item.title}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('YOUR NAME'),
                TextFormField(
                  controller: _nameController,
                  validator: _requiredValue,
                ),
                const SizedBox(height: 12),
                const _FieldLabel('CONTACT'),
                TextFormField(
                  controller: _contactController,
                  validator: _contactValidator,
                ),
                const SizedBox(height: 12),
                const _FieldLabel('PROOF OR PICKUP NOTES'),
                TextFormField(
                  controller: _messageController,
                  minLines: 3,
                  maxLines: 5,
                  validator: _requiredValue,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: const Icon(Icons.assignment_add),
                    label: const Text('Submit Claim'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await widget.controller.createClaim(
        item: widget.item,
        claimantName: _nameController.text,
        contact: _contactController.text,
        message: _messageController.text,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to submit claim. Check that Firestore rules are published.',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Claim submitted')));
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.menu, 'BROWSE'),
      (Icons.home_outlined, 'HOME'),
      (Icons.person, 'PROFILE'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: _BottomNavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    isSelected: selectedIndex == i,
                    onTap: () => onSelected(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _primaryBlue : _mutedInk;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        children: [
          Icon(icon, color: _primaryBlue, size: 34),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(color: _mutedInk),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _page,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _primaryBlue),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back, size: 18),
      style: IconButton.styleFrom(
        minimumSize: const Size(36, 36),
        fixedSize: const Size(36, 36),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _primaryBlue,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _primaryBlue,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + 8);
        canvas.drawPath(extractPath, paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

void _openReportPage(
  BuildContext context,
  CampusController controller,
  ItemStatus status,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          _ReportPage(controller: controller, initialStatus: status),
    ),
  );
}

Future<void> _openItemDetails(
  BuildContext context,
  CampusController controller,
  CampusItem item,
) {
  final itemId = item.id;
  if (itemId == null) {
    return Future.value();
  }

  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _ItemDetailsPage(controller: controller, itemId: itemId),
    ),
  );
}

Future<void> _showClaimForm(
  BuildContext context,
  CampusController controller,
  CampusItem item,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ClaimFormSheet(controller: controller, item: item),
  );
}
