import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme.dart';
import 'data/repositories/campus_store.dart';
import 'data/services/campus_database.dart';
import 'data/services/memory_campus_store.dart';
import 'features/home/providers/campus_controller.dart';
import 'features/home/views/campus_home.dart';

class CampusFindApp extends StatefulWidget {
  const CampusFindApp({super.key, this.store});

  final CampusStore? store;

  @override
  State<CampusFindApp> createState() => _CampusFindAppState();
}

class _CampusFindAppState extends State<CampusFindApp> {
  late final CampusController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CampusController(widget.store ?? _defaultStore())..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appName,
      theme: buildCampusFindTheme(),
      home: CampusHome(controller: _controller),
    );
  }

  CampusStore _defaultStore() {
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
}
