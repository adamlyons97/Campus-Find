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
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
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
  Future<UserModel?> registerWithEmailAndPassword(
      String email, String password, String name, String matricNo) async {
    try {
      if (!_isValidIIUMEmail(email)) {
        throw Exception('Registration restricted to @live.iium.edu.my domains.');
      }

      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create the structured UserModel object
      UserModel newUser = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        role: 'student', // Default role for new sign-ups
        joinedAt: DateTime.now(),
      );

      // Save the user profile to Cloud Firestore
      await _firestore.collection('users').doc(newUser.uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      throw Exception(e.toString());
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