class Profile {
  const Profile({
    required this.name,
    required this.email,
    required this.phone,
    required this.campus,
  });

  final String name;
  final String email;
  final String phone;
  final String campus;

  static const fallback = Profile(
    name: 'Campus Student',
    email: 'student@campus.edu',
    phone: '',
    campus: 'Main Campus',
  );

  Profile copyWith({
    String? name,
    String? email,
    String? phone,
    String? campus,
  }) {
    return Profile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      campus: campus ?? this.campus,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': 1,
      'name': name,
      'email': email,
      'phone': phone,
      'campus': campus,
    };
  }

  factory Profile.fromMap(Map<String, Object?> map) {
    return Profile(
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String,
      campus: map['campus'] as String,
    );
  }
}
