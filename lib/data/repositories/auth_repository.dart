import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/constants/firestore_paths.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

/// Encapsulates authentication (Feature 1 — Authentication Hub) and the
/// user profile document in Firestore.
class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestorePaths.users);

  /// Throws [AuthException] with a friendly message on failure.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    _assertUniversityEmail(email);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _fetchOrThrow(cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? mahallahFaculty,
  }) async {
    _assertUniversityEmail(email);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = UserModel(
        uid: cred.user!.uid,
        name: name.trim(),
        email: email.trim(),
        role: UserRole.student,
        joinedAt: DateTime.now(),
        mahallahFaculty: mahallahFaculty?.trim(),
      );
      await _users.doc(user.uid).set(user.toMap());
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapError(e));
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Streams the profile document for the signed-in user.
  Stream<UserModel?> userProfile(String uid) =>
      _users.doc(uid).snapshots().map(
            (doc) => doc.exists ? UserModel.fromDoc(doc) : null,
          );

  Future<UserModel> _fetchOrThrow(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      throw const AuthException('Profile not found. Please contact support.');
    }
    return UserModel.fromDoc(doc);
  }

  void _assertUniversityEmail(String email) {
    final lower = email.trim().toLowerCase();
    final ok = AppStrings.allowedEmailDomains
        .any((domain) => lower.endsWith('@$domain'));
    if (!ok) {
      throw AuthException(
        'Please use your university email '
        '(${AppStrings.allowedEmailDomains.map((d) => '@$d').join(', ')}).',
      );
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Please choose a stronger password (min 6 characters).';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  ),
);
