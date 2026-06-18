import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/firebase_runtime_config.dart';
import '../repositories/campus_store.dart';
import 'campus_database.dart';
import 'firebase_campus_store.dart';
import 'memory_campus_store.dart';

Future<CampusStore> createDefaultCampusStore() async {
  if (FirebaseRuntimeConfig.isConfigured) {
    try {
      await Firebase.initializeApp(options: FirebaseRuntimeConfig.options);
      return FirebaseCampusStore();
    } catch (_) {
      // Fall back to local storage so the app can still run while Firebase is
      // being configured.
    }
  }

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    try {
      await Firebase.initializeApp();
      return FirebaseCampusStore();
    } catch (_) {
      // A platform Firebase config file has not been installed yet.
    }
  }

  if (kIsWeb) {
    return MemoryCampusStore.seeded();
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return CampusDatabase.instance;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return MemoryCampusStore.seeded();
  }
}
