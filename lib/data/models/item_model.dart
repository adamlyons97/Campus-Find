import 'package:cloud_firestore/cloud_firestore.dart';

/// Nested object for `locationSeen` (Section 9.2.B).
class ItemLocation {
  final String name;
  final String specificDetails;

  const ItemLocation({this.name = '', this.specificDetails = ''});

  factory ItemLocation.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ItemLocation();
    return ItemLocation(
      name: map['name'] as String? ?? '',
      specificDetails: map['specificDetails'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'specificDetails': specificDetails,
      };
}

/// Mirrors `/items/{autoItemId}` (Section 9.2.B).
///
/// Lost and found items live in a single collection to streamline universal
/// search and the Gemini matching engine.
class ItemModel {
  final String id;
  final String title;
  final String description;
  final String type; // ItemType.lost | ItemType.found
  final String status; // ItemStatus.active | claimed | resolved
  final String categoryId;
  final String categoryName; // denormalised for fast display
  final String? imageUrl;
  final ItemLocation locationSeen;
  final DateTime reportedAt;
  final String reporterId;
  final String reporterName; // denormalised for fast display
  final bool isSoftDeleted;
  final String? finderClaimRequestNotes;

  const ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.reportedAt,
    required this.reporterId,
    required this.reporterName,
    this.imageUrl,
    this.locationSeen = const ItemLocation(),
    this.isSoftDeleted = false,
    this.finderClaimRequestNotes,
  });

  factory ItemModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final map = doc.data() ?? {};
    return ItemModel(
      id: doc.id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? 'lost',
      status: map['status'] as String? ?? 'active',
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? 'General',
      imageUrl: map['imageUrl'] as String?,
      locationSeen:
          ItemLocation.fromMap(map['locationSeen'] as Map<String, dynamic>?),
      reportedAt:
          (map['reportedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reporterId: map['reporterId'] as String? ?? '',
      reporterName: map['reporterName'] as String? ?? 'Anonymous',
      isSoftDeleted: map['isSoftDeleted'] as bool? ?? false,
      finderClaimRequestNotes: map['finderClaimRequestNotes'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'type': type,
        'status': status,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'imageUrl': imageUrl,
        'locationSeen': locationSeen.toMap(),
        'reportedAt': Timestamp.fromDate(reportedAt),
        'reporterId': reporterId,
        'reporterName': reporterName,
        'isSoftDeleted': isSoftDeleted,
        'finderClaimRequestNotes': finderClaimRequestNotes,
      };

  ItemModel copyWith({
    String? title,
    String? description,
    String? status,
    String? imageUrl,
  }) {
    return ItemModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type,
      status: status ?? this.status,
      categoryId: categoryId,
      categoryName: categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      locationSeen: locationSeen,
      reportedAt: reportedAt,
      reporterId: reporterId,
      reporterName: reporterName,
      isSoftDeleted: isSoftDeleted,
      finderClaimRequestNotes: finderClaimRequestNotes,
    );
  }

  /// Compact text used as input to the Gemini matching prompt.
  String toMatchableText() =>
      '[$type] $title — $description (category: $categoryName, '
      'location: ${locationSeen.name})';
}
