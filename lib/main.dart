import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_router.dart'; // Pull in our routing provider asset

void main() {
  runApp(
    const ProviderScope(
      child: CampusFindApp(),
    ),
  );
}

// Convert to a ConsumerWidget to allow this root level to read our appRouterProvider
class CampusFindApp extends ConsumerWidget {
  const CampusFindApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read the go_router configuration instance from our provider
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'CampusFind',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
        ),
      ),
      // Bind Flutter's layout engine to our declarative routing parameters
      routerConfig: router,
    );
  }
}