import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';
import '../data/models/project_model.dart';
import '../utils/result.dart';

/// Service for managing local storage operations using Hive
class StorageService {
  StorageService._();
  
  // Box names
  static const String projectsBoxName = AppConstants.projectsBoxName;
  static const String settingsBoxName = AppConstants.settingsBoxName;
  
  // Projects operations
  static Future<Result<void, String>> saveProject(Project project) async {
    try {
      final box = _getProjectsBox();
      await box.put(project.id, project.copyWith(
        updatedAt: DateTime.now(),
      ));
      _updateSettings('lastProjectUpdate', DateTime.now().toIso8601String());
      return const Result.success(null);
    } catch (e, stackTrace) {
      debugPrint('Error saving project: $e');
      debugPrint('Stack trace: $stackTrace');
      return Result.error('Failed to save project: ${e.toString()}');
    }
  }
  
  static Future<Result<Project?, String>> getProject(String id) async {
    try {
      final box = _getProjectsBox();
      final project = box.get(id);
      if (project == null) {
        return const Result.success(null);
      }
      return Result.success(project);
    } catch (e) {
      return Result.error('Failed to get project: $e');
    }
  }
  
  static Future<Result<List<Project>, String>> getProjects({
    ProjectStatus? status,
    bool sortByRecent = true,
    int limit = 50,
  }) async {
    try {
      final box = _getProjectsBox();
      List<Project> projects = box.values.cast<Project>().toList();
      
      // Filter by status if specified
      if (status != null) {
        projects = projects.where((p) => 
          p.status.value == status.value
        ).toList();
      }
      
      // Sort by updated date
      if (sortByRecent) {
        projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      }
      
      // Apply limit
      if (limit > 0) {
        projects = projects.take(limit).toList();
      }
      
      return Result.success(projects);
    } catch (e) {
      return Result.error('Failed to load projects: $e');
    }
  }
  
  static Future<Result<void, String>> deleteProject(String id) async {
    try {
      final box = _getProjectsBox();
      await box.delete(id);
      
      // Update last activity
      _updateSettings('lastProjectDelete', DateTime.now().toIso8601String());
      
      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to delete project: $e');
    }
  }
  
  static Future<Result<int, String>> deleteAllProjects() async {
    try {
      final box = _getProjectsBox();
      final count = box.length;
      await box.clear();
      await box.compact();
      
      _updateSettings(
        'lastDataClear', 
        DateTime.now().toIso8601String(),
      );
      
      return Result.success(count);
    } catch (e) {
      return Result.error('Failed to delete all projects: $e');
    }
  }
  
  static Future<Result<Project, String>> createProject({
    required String title,
    String? description,
    String language = 'dart',
    String platform = 'mobile',
  }) async {
    try {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final project = Project(
        id: id,
        title: title,
        description: description ?? '',
        files: [],
        status: ProjectStatus.draft,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        language: language,
        platform: platform,
        version: AppConstants.appVersion,
      );
      
      await saveProject(project);
      return Result.success(project);
    } catch (e) {
      return Result.error('Failed to create project: $e');
    }
  }
  
  // Settings operations
  static Future<Result<String?, String>> getSetting(String key) async {
    try {
      final box = _getSettingsBox();
      final value = box.get(key);
      return Result.success(value);
    } catch (e) {
      return Result.error('Failed to get setting $key: $e');
    }
  }
  
  static Future<Result<void, String>> setSetting(String key, String value) async {
    try {
      final box = _getSettingsBox();
      await box.put(key, value);
      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to set setting $key: $e');
    }
  }
  
  static Future<Result<void, String>> removeSetting(String key) async {
    try {
      final box = _getSettingsBox();
      await box.delete(key);
      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to remove setting $key: $e');
    }
  }
  
  static Future<Result<void, String>> clearSettings() async {
    try {
      final box = _getSettingsBox();
      await box.clear();
      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to clear settings: $e');
    }
  }
  
  // Search operations
  static Future<Result<List<Project>, String>> searchProjects(String query) async {
    try {
      if (query.isEmpty) {
        return await getProjects();
      }
      
      final allProjects = await getProjects();
      return allProjects.fold(
        (error) => Result.error(error),
        (projects) {
          final filtered = projects.where((project) {
            final lowerQuery = query.toLowerCase();
            return project.title.toLowerCase().contains(lowerQuery) ||
                   project.description.toLowerCase().contains(lowerQuery) ||
                   project.files.any((file) => 
                     file.displayName.toLowerCase().contains(lowerQuery) ||
                     file.path.toLowerCase().contains(lowerQuery)
                   );
          }).toList();
          
          return Result.success(filtered);
        },
      );
    } catch (e) {
      return Result.error('Failed to search projects: $e');
    }
  }
  
  // Backup operations
  static Future<Result<String, String>> exportProjectsToJson() async {
    try {
      final projectsResult = await getProjects();
      return projectsResult.fold(
        (error) => Result.error(error),
        (projects) async {
          final jsonData = {
            'exportDate': DateTime.now().toIso8601String(),
            'appVersion': AppConstants.appVersion,
            'projects': projects.map((p) => p.toJson()).toList(),
          };
          
          final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
          return Result.success(jsonString);
        },
      );
    } catch (e) {
      return Result.error('Failed to export projects: $e');
    }
  }
  
  // Private methods
  static Box<Project> _getProjectsBox() {
    return Hive.box<Project>(projectsBoxName);
  }
  
  static Box<String> _getSettingsBox() {
    return Hive.box<String>(settingsBoxName);
  }
  
  static void _updateSettings(String key, String value) {
    // Fire and forget - don't wait for settings update
    setSetting(key, value).ignore();
  }
  
  // Migration methods
  static Future<Result<void, String>> migrateFromOldVersion() async {
    try {
      // Check if migration is needed
      final migrationKey = 'migration_v1_0_completed';
      final migrationResult = await getSetting(migrationKey);
      
      if (migrationResult.isSuccess && migrationResult.value != null) {
        return const Result.success(null); // Already migrated
      }
      
      // Perform migration logic here if needed
      // For now, just mark as migrated
      await setSetting(migrationKey, DateTime.now().toIso8601String());
      
      return const Result.success(null);
    } catch (e) {
      return Result.error('Migration failed: $e');
    }
  }
}
