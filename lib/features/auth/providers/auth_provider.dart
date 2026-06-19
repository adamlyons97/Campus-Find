import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added to update the raw profile
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

// Provides a global instance of the AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Streams the current authentication state (useful for go_router redirects)
final authStateProvider = StreamProvider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

// Manages the loading/error state during the login/registration process
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithEmailAndPassword(
        email,
        password,
      );
      state = AsyncValue.data(user);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // NEW: Added phoneNumber to the incoming parameters to match the Sign Up UI
  Future<void> register(
    String email,
    String password,
    String name,
    String matricNo,
    String phoneNumber,
  ) async {
    state = const AsyncValue.loading();
    try {
      // 1. Create the account via your existing secure repository
      final userModel = await _authRepository.registerWithEmailAndPassword(
        email,
        password,
        name,
        matricNo,
        phoneNumber,
      );

      // 2. Grab the raw Firebase User session that was just created
      final firebaseUser = FirebaseAuth.instance.currentUser;

      if (firebaseUser != null) {
        // Update the core Firebase Auth display name instantly
        await firebaseUser.updateDisplayName(name.trim());

        // 3. Sync the extra data to the Firestore 'users' collection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
              'uid': firebaseUser.uid,
              'fullName': name.trim(),
              'matricNumber': matricNo.trim(),
              'email': email.trim(),
              'phoneNumber': phoneNumber
                  .trim(), // NEW: Saves the mobile number to the database!
              'role':
                  'student', // Good practice to explicitly set the default role here
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      state = AsyncValue.data(userModel);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
    state = const AsyncValue.data(null);
  }
}
