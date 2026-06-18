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
    this.latitude,
    this.longitude,
    required this.status,
    ItemStatus? reportType,
    this.ownerUid = '',
    required this.reporterName,
    required this.contact,
    this.imageData,
    required this.createdAt,
    required this.updatedAt,
  }) : reportType =
           reportType ??
           (status == ItemStatus.found ? ItemStatus.found : ItemStatus.lost);

  final int? id;
  final String title;
  final String description;
  final String category;
  final String location;
  final double? latitude;
  final double? longitude;
  final ItemStatus status;
  final ItemStatus reportType;
  final String ownerUid;
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
    double? latitude,
    double? longitude,
    ItemStatus? status,
    ItemStatus? reportType,
    String? ownerUid,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      reportType: reportType ?? this.reportType,
      ownerUid: ownerUid ?? this.ownerUid,
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
      'latitude': latitude,
      'longitude': longitude,
      'status': status.databaseValue,
      'report_type': reportType.databaseValue,
      'owner_uid': ownerUid,
      'reporter_name': reporterName,
      'contact': contact,
      'image_data': imageData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CampusItem.fromMap(Map<String, Object?> map) {
    return CampusItem(
      id: _intFromMap(map['id']),
      title: map['title'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      location: map['location'] as String,
      latitude: _doubleFromMap(map['latitude']),
      longitude: _doubleFromMap(map['longitude']),
      status: ItemStatusDetails.fromDatabase(map['status'] as String),
      reportType: ItemStatusDetails.fromDatabase(
        map['report_type'] as String? ??
            ((map['status'] as String) == ItemStatus.found.databaseValue
                ? ItemStatus.found.databaseValue
                : ItemStatus.lost.databaseValue),
      ),
      ownerUid: map['owner_uid'] as String? ?? '',
      reporterName: map['reporter_name'] as String,
      contact: map['contact'] as String,
      imageData: map['image_data'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

extension CampusItemStatus on CampusItem {
  String get resolvedLabel =>
      reportType == ItemStatus.found ? 'Returned' : 'Received';

  String get displayStatusLabel =>
      status == ItemStatus.claimed ? resolvedLabel : status.label;
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

double? _doubleFromMap(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}
