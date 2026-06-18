import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/firestore_paths.dart';
import '../../../core/theme.dart';
import '../providers/gemini_search_provider.dart';

class AiSearchScreen extends ConsumerStatefulWidget {
  const AiSearchScreen({super.key});

  @override
  ConsumerState<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends ConsumerState<AiSearchScreen> {
  final _query = TextEditingController();
  String _searchType = ItemType.found; // search found listings by default

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _run() {
    FocusScope.of(context).unfocus();
    ref.read(geminiSearchControllerProvider.notifier).search(
          description: _query.text,
          searchType: _searchType,
        );
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(geminiSearchControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 20),
            SizedBox(width: 8),
            Text('AI Smart Search'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: ItemType.found, label: Text('Search Found')),
                    ButtonSegment(
                        value: ItemType.lost, label: Text('Search Lost')),
                  ],
                  selected: {_searchType},
                  onSelectionChanged: (s) =>
                      setState(() => _searchType = s.first),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _query,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Describe the item in your own words',
                    hintText: 'e.g. a black Casio watch with a scratched face, '
                        'lost near the library',
                  ),
                  onSubmitted: (_) => _run(),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: results.isLoading ? null : _run,
                  icon: const Icon(Icons.search),
                  label: const Text('Find Matches with AI'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: results.when(
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Gemini is analysing descriptions…'),
                  ],
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(e.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (hits) {
                if (hits.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No strong matches yet.\nTry adding more detail '
                        'like colour, brand or where you last saw it.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: hits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (_, i) {
                    final hit = hits[i];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary,
                          child: Text('${hit.confidence}%',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                        title: Text(hit.item.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(hit.reason,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/item/${hit.item.id}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
