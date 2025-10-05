import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/hive/hive_adapters.dart';
import 'data/models/project_file_model.dart';
import 'data/models/project_model.dart';
import 'services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  
  // Register adapters
  registerHiveAdapters();
  
  // Open boxes
  await Hive.openBox<Project>(StorageService.projectsBoxName);

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
