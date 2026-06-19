// Widget tests for CampusFind authentication.
//
// Tests the LoginScreen form validation rules (IIUM email domain and
// minimum password length) in isolation, without requiring Firebase.
// The AuthRepository is overridden with a fake so no live Firebase
// connection is needed in the test environment.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:campus_find/data/repositories/auth_repository.dart';
import 'package:campus_find/data/models/user_model.dart';
import 'package:campus_find/features/auth/providers/auth_provider.dart';
import 'package:campus_find/features/auth/views/login_screen.dart';

// A fake repository so the widget tree never touches live Firebase.
class FakeAuthRepository implements AuthRepository {
  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async => null;

  @override
  Future<UserModel?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    String matricNo,
    String phoneNumber,
  ) async => null;

  @override
  Future<UserModel?> getUserData(String uid) async => null;

  @override
  Future<void> signOut() async {}
}

Widget _wrapLogin() => ProviderScope(
  overrides: [authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
  child: const MaterialApp(home: LoginScreen()),
);

void main() {
  testWidgets('LoginScreen rejects a non-IIUM email domain', (tester) async {
    await tester.pumpWidget(_wrapLogin());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'someone@gmail.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.text('SECURE LOGIN'));
    await tester.pump();

    expect(
      find.text('Must be a valid @live.iium.edu.my domain'),
      findsOneWidget,
    );
  });

  testWidgets('LoginScreen rejects a password shorter than 6 characters', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapLogin());
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).first,
      'ammar@live.iium.edu.my',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('SECURE LOGIN'));
    await tester.pump();

    expect(find.text('Password too short'), findsOneWidget);
  });
}
