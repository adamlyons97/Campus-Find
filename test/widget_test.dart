import 'package:campus_find/app_router.dart';
import 'package:campus_find/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('CampusFind app renders its configured route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: Text('CampusFind test home')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(router)],
        child: const CampusFindApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CampusFind test home'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
