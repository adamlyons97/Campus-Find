import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/match_repository.dart';
import '../../../data/models/match_model.dart';

// Expose the repository
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

// A family stream provider. It requires an 'itemId' string to be passed in,
// and returns a live stream of matches just for that specific item!
final itemMatchesStreamProvider =
    StreamProvider.family<List<MatchModel>, String>((ref, itemId) {
      final repository = ref.watch(matchRepositoryProvider);
      return repository.getMatchesForItem(itemId);
    });
