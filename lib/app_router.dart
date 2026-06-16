import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/auth/views/login_screen.dart';
import 'features/auth/views/register_screen.dart';
import 'features/browse/views/browse_screen.dart';
import 'features/claims/views/claim_management_screen.dart';
import 'features/claims/views/my_claims_screen.dart';
import 'features/create_post/views/create_item_form.dart';
import 'features/home/views/home_dashboard.dart';
import 'features/home/views/my_items_screen.dart';
import 'features/item_detail/views/item_detail_screen.dart';
import 'features/profile/views/profile_screen.dart';
import 'features/search/views/ai_search_screen.dart';
import 'features/shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _browseNavKey = GlobalKey<NavigatorState>();
final _homeNavKey = GlobalKey<NavigatorState>();
final _profileNavKey = GlobalKey<NavigatorState>();

/// go_router configuration with an auth-aware redirect and a persistent
/// bottom-navigation shell (Browse / Home / Profile).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loggedIn = authState.valueOrNull != null;
      final loc = state.matchedLocation;
      final loggingIn = loc == '/login' || loc == '/register';

      if (authState.isLoading) return null;
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggedIn && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Primary tabs with a shared bottom navigation bar.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _browseNavKey,
            routes: [
              GoRoute(
                  path: '/browse', builder: (_, __) => const BrowseScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _homeNavKey,
            routes: [
              GoRoute(
                  path: '/home', builder: (_, __) => const HomeDashboard()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavKey,
            routes: [
              GoRoute(
                  path: '/profile',
                  builder: (_, __) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      // Full-screen routes pushed over the shell.
      GoRoute(
        path: '/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            CreateItemForm(initialType: state.uri.queryParameters['type']),
      ),
      GoRoute(
          path: '/search',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const AiSearchScreen()),
      GoRoute(
          path: '/my-items',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const MyItemsScreen()),
      GoRoute(
          path: '/my-claims',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const MyClaimsScreen()),
      GoRoute(
          path: '/verify',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const ClaimManagementScreen()),
      GoRoute(
        path: '/item/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            ItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
    ],
  );
});

/// Bridges the Riverpod auth provider to go_router's refresh mechanism so
/// the redirect re-runs whenever auth state changes.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
