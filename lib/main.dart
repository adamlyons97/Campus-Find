import 'package:flutter/material.dart';

import 'app_router.dart';
import 'data/services/default_campus_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await createDefaultCampusStore();
  runApp(CampusFindApp(store: store));
}
