import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Wrap the root widget with ProviderScope to enable Riverpod state handling
  runApp(
    const ProviderScope(
      child: CampusFindApp(),
    ),
  );
}

class CampusFindApp extends StatelessWidget {
  const CampusFindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusFind',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Welcome to CampusFind'),
        ),
      ),
    );
  }
}