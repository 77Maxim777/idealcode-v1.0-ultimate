import 'package:hive/hive.dart';

import '../models/project_file_model.dart';
import '../models/project_model.dart';

void registerHiveAdapters() {
  // Register adapters for models
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ProjectFileAdapter());
  Hive.registerAdapter(ProjectStatusAdapter());
  Hive.registerAdapter(FileStatusAdapter());
  Hive.registerAdapter(FileTypeAdapter());
}
