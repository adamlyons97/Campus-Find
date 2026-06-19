class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phoneNumber; // NEW FIELD
  final String role;
  final DateTime joinedAt;
  final String? mahallahFaculty;
  final int totalItemsReported;
  final int totalItemsReunited;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phoneNumber, // NEW FIELD
    required this.role,
    required this.joinedAt,
    this.mahallahFaculty,
    this.totalItemsReported = 0,
    this.totalItemsReunited = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '', // NEW FIELD
      role: map['role'] ?? 'student',
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as dynamic).toDate()
          : DateTime.now(),
      mahallahFaculty: map['mahallah_faculty'],
      totalItemsReported: map['totalItemsReported']?.toInt() ?? 0,
      totalItemsReunited: map['totalItemsReunited']?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber, // NEW FIELD
      'role': role,
      'joinedAt': joinedAt,
      'mahallah_faculty': mahallahFaculty,
      'totalItemsReported': totalItemsReported,
      'totalItemsReunited': totalItemsReunited,
    };
  }
}
