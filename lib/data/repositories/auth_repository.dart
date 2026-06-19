import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream to listen to auth state changes (logged in vs logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Helper method to validate the university domain
  bool _isValidIIUMEmail(String email) {
    return email.trim().toLowerCase().endsWith('@live.iium.edu.my');
  }

  /// Logs in an existing user
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (!_isValidIIUMEmail(email)) {
        throw Exception('Only @live.iium.edu.my emails are authorized.');
      }

      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return await getUserData(credential.user!.uid);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Registers a new user and creates their Firestore profile
  // 1. Add String phoneNumber to the function parameters here:
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String matricNo,
    String phoneNumber,
  ) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Add phoneNumber to the UserModel creation here:
      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        name: name,
        email: email,
        role: 'student',
        joinedAt: DateTime.now(),
        phoneNumber: phoneNumber, // <--- ADD THIS LINE
      );

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches the user's profile from Firestore
  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  /// Logs the user out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
