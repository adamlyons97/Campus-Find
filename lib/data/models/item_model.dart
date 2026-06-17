class LocationSeen {
  final String name;
  final String specificDetails;

  LocationSeen({required this.name, required this.specificDetails});

  factory LocationSeen.fromMap(Map<String, dynamic> map) {
    return LocationSeen(
      name: map['name'] ?? '',
      specificDetails: map['specificDetails'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'specificDetails': specificDetails,
    };
  }
}

class ItemModel {
  final String itemId;
  final String title;
  final String description;
  final String type; // 'lost' or 'found'
  final String status; // 'active', 'claimed', 'resolved'
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final LocationSeen locationSeen;
  final DateTime reportedAt;
  final String reportedBy; // Links to UserModel.uid
  final String reportedByName;
  final bool isSoftDeleted;
  final String? finderClaimRequestNotes;

  ItemModel({
    required this.itemId,
    required this.title,
    required this.description,
    required this.type,
    this.status = 'active',
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    required this.locationSeen,
    required this.reportedAt,
    required this.reportedBy,
    required this.reportedByName,
    this.isSoftDeleted = false,
    this.finderClaimRequestNotes,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ItemModel(
      itemId: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'lost',
      status: map['status'] ?? 'active',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      imageUrl: map['imageUrl'],
      locationSeen: LocationSeen.fromMap(map['locationSeen'] ?? {}),
      reportedAt: map['reportedAt'] != null 
          ? (map['reportedAt'] as dynamic).toDate() 
          : DateTime.now(),
      reportedBy: map['reportedBy'] ?? '',
      reportedByName: map['reportedByName'] ?? '',
      isSoftDeleted: map['isSoftDeleted'] ?? false,
      finderClaimRequestNotes: map['finderClaimRequestNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'locationSeen': locationSeen.toMap(),
      'reportedAt': reportedAt,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'isSoftDeleted': isSoftDeleted,
      'finderClaimRequestNotes': finderClaimRequestNotes,
    };
  }
}