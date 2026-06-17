import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Import the core Firebase engine
import 'package:firebase_core/firebase_core.dart'; 
// 2. Import your newly generated keys
import 'firebase_options.dart'; 

import 'app_router.dart';

void main() async {
  // 3. Ensure Flutter bindings are ready before waking up Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // 4. Boot up Firebase using the correct keys for your device
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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