class MatchModel {
  final String matchId;
  final String newItemId;
  final String matchedItemId;
  final DateTime detectedAt;
  final double confidenceScore;
  final String status; // 'pending_review', 'accepted', 'rejected', 'resolved'

  MatchModel({
    required this.matchId,
    required this.newItemId,
    required this.matchedItemId,
    required this.detectedAt,
    required this.confidenceScore,
    required this.status,
  });

  factory MatchModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MatchModel(
      matchId: documentId,
      newItemId: map['newItemId'] ?? '',
      matchedItemId: map['matchedItemId'] ?? '',
      detectedAt: map['detectedAt'] != null 
          ? (map['detectedAt'] as dynamic).toDate() 
          : DateTime.now(),
      confidenceScore: (map['confidenceScore'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'pending_review',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'newItemId': newItemId,
      'matchedItemId': matchedItemId,
      'detectedAt': detectedAt,
      'confidenceScore': confidenceScore,
      'status': status,
    };
  }
}