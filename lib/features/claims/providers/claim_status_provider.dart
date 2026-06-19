import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/claim_model.dart';
import '../../../data/repositories/claim_repository.dart';

/// Pending claims awaiting verification (verifier dashboard).
final pendingClaimsProvider = StreamProvider.autoDispose<List<ClaimModel>>(
  (ref) => ref.watch(claimRepositoryProvider).watchPendingClaims(),
);

/// The current user's submitted claims.
final myClaimsProvider =
    StreamProvider.autoDispose.family<List<ClaimModel>, String>((ref, uid) {
  return ref.watch(claimRepositoryProvider).watchClaimsByClaimant(uid);
});

/// Claims attached to a single item (shown on the item detail screen).
final claimsForItemProvider =
    StreamProvider.autoDispose.family<List<ClaimModel>, String>((ref, itemId) {
  return ref.watch(claimRepositoryProvider).watchClaimsForItem(itemId);
});

/// Submits and moderates claims.
class ClaimController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> submit({
    required String itemId,
    required String itemTitle,
    required String reporterId,
    required String proofOfOwnership,
  }) async {
    final auth = FirebaseAuth.instance.currentUser;
    if (auth == null) {
      state = AsyncError('Not signed in', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(claimRepositoryProvider).submitClaim(
            itemId: itemId,
            itemTitle: itemTitle,
            claimantId: auth.uid,
            claimantName: auth.displayName ?? auth.email ?? 'Member',
            reporterId: reporterId,
            proofOfOwnership: proofOfOwnership.trim(),
          );
    });
    return !state.hasError;
  }

  Future<void> approve({
    required String claimId,
    required String itemId,
    String? finderNotes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(claimRepositoryProvider).approveClaim(
            claimId: claimId,
            itemId: itemId,
            finderNotes: finderNotes,
          ),
    );
  }

  Future<void> reject({
    required String claimId,
    required String itemId,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(claimRepositoryProvider).rejectClaim(
            claimId: claimId,
            itemId: itemId,
          ),
    );
  }
}

final claimControllerProvider =
    AutoDisposeAsyncNotifierProvider<ClaimController, void>(
  ClaimController.new,
);
