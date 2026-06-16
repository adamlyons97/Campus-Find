import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors `/claims/{autoClaimId}` (Section 9.2.D).
///
/// Governs the verification process of reuniting an owner with their
/// belongings — the heart of the Shariah-compliant Luqatah flow.
class ClaimModel {
  final String id;
  final String itemId;
  final String claimantId;
  final String reporterId; // owner of the found post
  final String proofOfOwnership; // claimant's natural-language proof
  final DateTime claimedAt;
  final DateTime updatedAt;
  final String status; // ClaimStatus.pending | approved | rejected
  final String? finderNotes;

  // Denormalised helpers for list rendering (not part of the core schema
  // but harmless and avoids N extra reads in the verifier dashboard).
  final String? itemTitle;
  final String? claimantName;

  const ClaimModel({
    required this.id,
    required this.itemId,
    required this.claimantId,
    required this.reporterId,
    required this.proofOfOwnership,
    required this.claimedAt,
    required this.updatedAt,
    required this.status,
    this.finderNotes,
    this.itemTitle,
    this.claimantName,
  });

  factory ClaimModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return ClaimModel(
      id: doc.id,
      itemId: map['itemId'] as String? ?? '',
      claimantId: map['claimantId'] as String? ?? '',
      reporterId: map['reporterId'] as String? ?? '',
      proofOfOwnership: map['proofOfOwnership'] as String? ?? '',
      claimedAt: (map['claimedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] as String? ?? 'pending',
      finderNotes: map['finderNotes'] as String?,
      itemTitle: map['itemTitle'] as String?,
      claimantName: map['claimantName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'claimantId': claimantId,
        'reporterId': reporterId,
        'proofOfOwnership': proofOfOwnership,
        'claimedAt': Timestamp.fromDate(claimedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'status': status,
        'finderNotes': finderNotes,
        'itemTitle': itemTitle,
        'claimantName': claimantName,
      };
}
