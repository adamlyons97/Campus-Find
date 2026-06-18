import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/auth/views/login_screen.dart';
import 'features/auth/views/sign_up_screen.dart';
import 'features/home/views/home_dashboard.dart';
import 'features/create_post/views/create_post_screen.dart';
import 'features/claims/views/my_posts_screen.dart';
import 'features/claims/views/match_details_screen.dart';
import 'features/auth/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final isAuthenticated = authState.valueOrNull != null;
      final isNavigatingToAuth = state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!isAuthenticated && !isNavigatingToAuth) return '/login';
      if (isAuthenticated && isNavigatingToAuth) return '/home';
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
      // NEW ROUTE DECLARED HERE
      GoRoute(
        path: '/create-post',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/my-posts',
        name: 'my-posts',
        builder: (context, state) => const MyPostsScreen(),
      ),
      GoRoute(
        path: '/match-details',
        name: 'match-details',
        builder: (context, state) {
          // Extract the IDs from the URL query parameters
          final matchId = state.uri.queryParameters['matchId']!;
          final matchedItemId = state.uri.queryParameters['matchedItemId']!;
          
          return MatchDetailsScreen(
            matchId: matchId,
            matchedItemId: matchedItemId,
          );
        },
      ),
    ],
  );
});