import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';

/// Mirrors `/users/{uid}` (Section 9.2.A).
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime joinedAt;
  final String? mahallahFaculty;
  final int totalItemsReported;
  final int totalItemsReunited;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.mahallahFaculty,
    this.totalItemsReported = 0,
    this.totalItemsReunited = 0,
  });

  bool get isVerifier => UserRole.verifiers.contains(role);

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? UserRole.student,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      mahallahFaculty: map['mahallah_faculty'] as String?,
      totalItemsReported: (map['totalItemsReported'] as num?)?.toInt() ?? 0,
      totalItemsReunited: (map['totalItemsReunited'] as num?)?.toInt() ?? 0,
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'mahallah_faculty': mahallahFaculty,
        'totalItemsReported': totalItemsReported,
        'totalItemsReunited': totalItemsReunited,
      };

  UserModel copyWith({
    String? name,
    String? role,
    String? mahallahFaculty,
    int? totalItemsReported,
    int? totalItemsReunited,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      joinedAt: joinedAt,
      mahallahFaculty: mahallahFaculty ?? this.mahallahFaculty,
      totalItemsReported: totalItemsReported ?? this.totalItemsReported,
      totalItemsReunited: totalItemsReunited ?? this.totalItemsReunited,
    );
  }
}
