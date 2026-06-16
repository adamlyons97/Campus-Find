/// Single source of truth for Firestore collection names, matching the
/// data model defined in Section 9 of the project README.
class FirestorePaths {
  FirestorePaths._();

  static const String users = 'users';
  static const String items = 'items';
  static const String itemCategories = 'itemCategories';
  static const String claims = 'claims';
}

/// Enumerated string values used across documents, kept central so the UI,
/// repositories and security rules stay consistent.
class ItemType {
  static const String lost = 'lost';
  static const String found = 'found';
}

class ItemStatus {
  static const String active = 'active';
  static const String claimed = 'claimed';
  static const String resolved = 'resolved';
}

class ClaimStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class UserRole {
  static const String student = 'student';
  static const String staff = 'staff';
  static const String security = 'security';
  static const String admin = 'admin';

  /// Roles permitted to approve/reject claims (safe depository authorities).
  static const List<String> verifiers = [security, admin];
}
