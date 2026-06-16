enum ItemStatus { lost, found, claimed }

extension ItemStatusDetails on ItemStatus {
  String get label {
    switch (this) {
      case ItemStatus.lost:
        return 'Lost';
      case ItemStatus.found:
        return 'Found';
      case ItemStatus.claimed:
        return 'Claimed';
    }
  }

  String get databaseValue => name;

  static ItemStatus fromDatabase(String value) {
    return ItemStatus.values.firstWhere(
      (status) => status.databaseValue == value,
      orElse: () => ItemStatus.lost,
    );
  }
}

class CampusItem {
  const CampusItem({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterName,
    required this.contact,
    this.imageData,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String description;
  final String category;
  final String location;
  final ItemStatus status;
  final String reporterName;
  final String contact;
  final String? imageData;
  final DateTime createdAt;
  final DateTime updatedAt;

  CampusItem copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? location,
    ItemStatus? status,
    String? reporterName,
    String? contact,
    String? imageData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampusItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      location: location ?? this.location,
      status: status ?? this.status,
      reporterName: reporterName ?? this.reporterName,
      contact: contact ?? this.contact,
      imageData: imageData ?? this.imageData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'location': location,
      'status': status.databaseValue,
      'reporter_name': reporterName,
      'contact': contact,
      'image_data': imageData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CampusItem.fromMap(Map<String, Object?> map) {
    return CampusItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      location: map['location'] as String,
      status: ItemStatusDetails.fromDatabase(map['status'] as String),
      reporterName: map['reporter_name'] as String,
      contact: map['contact'] as String,
      imageData: map['image_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
