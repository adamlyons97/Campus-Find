import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:campusfind/data/memory_campus_store.dart';
import 'package:campusfind/main.dart';

void main() {
  testWidgets('CampusFind signs in and opens the seeded dashboard', (
    tester,
  ) async {
    await tester.pumpWidget(CampusFindApp(store: MemoryCampusStore.seeded()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Back'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'student@campus.edu',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'campusfind');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('CampusFind'), findsAtLeastNWidgets(1));
    expect(find.text('Report\nLost Item'), findsOneWidget);
    expect(find.text('Black Hydro Flask'), findsOneWidget);
  });
}
