class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // e.g., 'student', 'staff', 'security', 'admin'
  final DateTime joinedAt;
  final String? mahallahFaculty; // Optional field
  final int totalItemsReported;
  final int totalItemsReunited;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.mahallahFaculty,
    this.totalItemsReported = 0,
    this.totalItemsReunited = 0,
  });

  // Converts Firestore JSON document into our Dart Object
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
      // Handles Firestore Timestamp conversion to Dart DateTime
      joinedAt: map['joinedAt'] != null 
          ? (map['joinedAt'] as dynamic).toDate() 
          : DateTime.now(),
      mahallahFaculty: map['mahallah_faculty'],
      totalItemsReported: map['totalItemsReported']?.toInt() ?? 0,
      totalItemsReunited: map['totalItemsReunited']?.toInt() ?? 0,
    );
  }

  // Converts our Dart Object back into a JSON map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'joinedAt': joinedAt, // Firestore SDK will convert this back to Timestamp automatically
      'mahallah_faculty': mahallahFaculty,
      'totalItemsReported': totalItemsReported,
      'totalItemsReunited': totalItemsReunited,
    };
  }
}