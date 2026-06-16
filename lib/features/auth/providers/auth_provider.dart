import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';

/// Raw Firebase auth state — drives the router redirect.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// The signed-in user's Firestore profile (null while logged out).
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).userProfile(auth.uid);
});

/// Controller for the login & registration forms. Exposes an [AsyncValue]
/// so the UI can show loading / error states without manual flags.
class AuthController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  Future<bool> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.signIn(email: email, password: password),
    );
    return !state.hasError;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? mahallahFaculty,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.register(
        name: name,
        email: email,
        password: password,
        mahallahFaculty: mahallahFaculty,
      ),
    );
    return !state.hasError;
  }

  Future<void> signOut() => _repo.signOut();
}

final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, void>(
  AuthController.new,
);
