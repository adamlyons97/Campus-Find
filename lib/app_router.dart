import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/views/login_screen.dart';
import 'features/auth/views/sign_up_screen.dart';
import 'features/home/views/home_dashboard.dart';
import 'features/auth/providers/auth_provider.dart'; // NEW: Import the auth provider

final appRouterProvider = Provider<GoRouter>((ref) {
  // 1. Watch the continuous Firebase authentication stream
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    
    // 2. The Global Route Guard
    redirect: (context, state) {
      // If Firebase is still verifying the session, do nothing yet
      if (authState.isLoading) return null;

      // Determine if a valid user session exists in the stream
      final isAuthenticated = authState.valueOrNull != null;
      
      // Determine if the user is currently on (or heading to) the Auth screens
      final isNavigatingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      // Rule 1: If NOT authenticated and trying to access a protected screen (like /home), kick to /login
      if (!isAuthenticated && !isNavigatingToAuth) {
        return '/login';
      }

      // Rule 2: If IS authenticated and trying to look at /login or /signup, push to /home
      if (isAuthenticated && isNavigatingToAuth) {
        return '/home';
      }

      // Rule 3: Allow normal navigation if no security rules are violated
      return null;
    },

    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeDashboard(),
      ),
    ],
  );
});