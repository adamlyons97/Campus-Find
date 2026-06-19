// Basic smoke test for CampusFind.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:campus_find/main.dart';

void main() {
  testWidgets('CampusFindApp builds without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: CampusFindApp()));
    await tester.pump();
  });
}
