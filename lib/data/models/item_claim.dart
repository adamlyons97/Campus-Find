enum ClaimStatus { pending, approved, rejected }

extension ClaimStatusDetails on ClaimStatus {
  String get label {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
    }
  }

  String get databaseValue => name;

  static ClaimStatus fromDatabase(String value) {
    return ClaimStatus.values.firstWhere(
      (status) => status.databaseValue == value,
      orElse: () => ClaimStatus.pending,
    );
  }
}

class ItemClaim {
  const ItemClaim({
    this.id,
    required this.itemId,
    this.claimantUid = '',
    required this.claimantName,
    required this.contact,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  final int? id;
  final int itemId;
  final String claimantUid;
  final String claimantName;
  final String contact;
  final String message;
  final ClaimStatus status;
  final DateTime createdAt;

  ItemClaim copyWith({
    int? id,
    int? itemId,
    String? claimantUid,
    String? claimantName,
    String? contact,
    String? message,
    ClaimStatus? status,
    DateTime? createdAt,
  }) {
    return ItemClaim(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      claimantUid: claimantUid ?? this.claimantUid,
      claimantName: claimantName ?? this.claimantName,
      contact: contact ?? this.contact,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'claimant_uid': claimantUid,
      'claimant_name': claimantName,
      'contact': contact,
      'message': message,
      'status': status.databaseValue,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ItemClaim.fromMap(Map<String, Object?> map) {
    return ItemClaim(
      id: _intFromMap(map['id']),
      itemId: _intFromMap(map['item_id']) ?? 0,
      claimantUid: map['claimant_uid'] as String? ?? '',
      claimantName: map['claimant_name'] as String,
      contact: map['contact'] as String,
      message: map['message'] as String,
      status: ClaimStatusDetails.fromDatabase(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

int? _intFromMap(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
