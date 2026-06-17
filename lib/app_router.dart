import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/views/login_screen.dart';
import 'features/auth/views/sign_up_screen.dart'; // NEW IMPORT
import 'features/home/views/home_dashboard.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      // NEW ROUTE ADDED HERE
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