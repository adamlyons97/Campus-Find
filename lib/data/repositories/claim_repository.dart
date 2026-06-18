import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_paths.dart';
import '../models/claim_model.dart';
import '../services/firebase_service.dart';

/// Manages the `claims` collection — the Shariah-compliant verification
/// process (Feature 4 — Secure Claim System).
class ClaimRepository {
  ClaimRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _claims =>
      _db.collection(FirestorePaths.claims);

  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection(FirestorePaths.items);

  /// Submits a claim with the claimant's proof of ownership and atomically
  /// moves the item from `active` to `claimed` (locked while under review).
  /// Status begins as `pending` until a verifier approves it.
  Future<String> submitClaim({
    required String itemId,
    required String itemTitle,
    required String claimantId,
    required String claimantName,
    required String reporterId,
    required String proofOfOwnership,
  }) async {
    final now = DateTime.now();
    final docRef = _claims.doc();
    final claim = ClaimModel(
      id: '',
      itemId: itemId,
      itemTitle: itemTitle,
      claimantId: claimantId,
      claimantName: claimantName,
      reporterId: reporterId,
      proofOfOwnership: proofOfOwnership,
      claimedAt: now,
      updatedAt: now,
      status: ClaimStatus.pending,
    );
    final batch = _db.batch();
    batch.set(docRef, claim.toMap());
    batch.update(_items.doc(itemId), {'status': ItemStatus.claimed});
    await batch.commit();
    return docRef.id;
  }

  /// Live stream of all claims submitted by a user.
  Stream<List<ClaimModel>> watchClaimsByClaimant(String claimantId) => _claims
      .where('claimantId', isEqualTo: claimantId)
      .orderBy('claimedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ClaimModel.fromDoc).toList());

  /// Live stream of pending claims awaiting verification — the verifier
  /// (security/admin) dashboard.
  Stream<List<ClaimModel>> watchPendingClaims() => _claims
      .where('status', isEqualTo: ClaimStatus.pending)
      .orderBy('claimedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ClaimModel.fromDoc).toList());

  Stream<List<ClaimModel>> watchClaimsForItem(String itemId) => _claims
      .where('itemId', isEqualTo: itemId)
      .orderBy('claimedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ClaimModel.fromDoc).toList());

  /// Approves a claim and atomically marks the item as resolved.
  Future<void> approveClaim({
    required String claimId,
    required String itemId,
    String? finderNotes,
  }) async {
    final batch = _db.batch();
    batch.update(_claims.doc(claimId), {
      'status': ClaimStatus.approved,
      'updatedAt': Timestamp.now(),
      if (finderNotes != null) 'finderNotes': finderNotes,
    });
    batch.update(_items.doc(itemId), {'status': ItemStatus.resolved});
    await batch.commit();
  }

  /// Rejects a claim and atomically returns the item to the `active` pool so
  /// it can be discovered and claimed again.
  Future<void> rejectClaim({
    required String claimId,
    required String itemId,
  }) async {
    final batch = _db.batch();
    batch.update(_claims.doc(claimId), {
      'status': ClaimStatus.rejected,
      'updatedAt': Timestamp.now(),
    });
    batch.update(_items.doc(itemId), {'status': ItemStatus.active});
    await batch.commit();
  }
}

final claimRepositoryProvider = Provider<ClaimRepository>(
  (ref) => ClaimRepository(ref.watch(firestoreProvider)),
);
