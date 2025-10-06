import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/hive/hive_adapters.dart';
import 'data/models/project_file_model.dart';
import 'data/models/project_model.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await _initHive();
  
  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}

Future<void> _initHive() async {
  try {
    await Hive.initFlutter();
    
    // Register all adapters
    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(ProjectFileAdapter());
    Hive.registerAdapter(ProjectStatusAdapter());
    Hive.registerAdapter(FileStatusAdapter());
    Hive.registerAdapter(FileTypeAdapter());
    
    // Open boxes
    await Hive.openBox<Project>(StorageService.projectsBoxName);
    await Hive.openBox<String>(StorageService.settingsBoxName);
  } catch (e) {
    debugPrint('Error initializing Hive: $e');
  }
}
