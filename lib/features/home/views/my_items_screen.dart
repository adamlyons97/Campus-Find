import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/item_list_provider.dart';
import '../widgets/item_card.dart';

class MyItemsScreen extends ConsumerWidget {
  const MyItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: auth == null
          ? const Center(child: Text('Not signed in'))
          : ref.watch(myItemsProvider(auth.uid)).when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(e.toString())),
                data: (items) => items.isEmpty
                    ? const Center(child: Text('You have no reports yet.'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (_, i) => ItemCard(
                          item: items[i],
                          onTap: () => context.push('/item/${items[i].id}'),
                        ),
                      ),
              ),
    );
  }
}
