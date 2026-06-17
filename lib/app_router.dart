import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import our newly created presentation stubs
import 'features/auth/views/login_screen.dart';
import 'features/home/views/home_dashboard.dart';

/// Global provider exposing the go_router configuration throughout the application scope.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login', // Defaults straight to security check
    debugLogDiagnostics: true, // Prints routing changes directly to the terminal console
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeDashboard(),
      ),
    ],
    
    // TODO: Implement dynamic route guards based on Firebase Auth state shifts
    redirect: (context, state) {
      return null; // Current pass-through; logic will block non-IIUM accounts later
    },
  );
});