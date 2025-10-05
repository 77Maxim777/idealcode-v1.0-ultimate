import 'package:hive/hive.dart';

import '../core/constants/app_constants.dart';
import '../data/models/project_model.dart';
import '../utils/result.dart';

class StorageService {
  const StorageService._();

  static const String projectsBoxName = AppConstants.projectsBoxName;

  static Future<Result<void, String>> saveProject(Project project) async {
    try {
      final box = Hive.box<Project>(projectsBoxName);
      await box.put(project.id, project);
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to save project: $e');
    }
  }

  static Future<Result<Project?, String>> getProject(String id) async {
    try {
      final box = Hive.box<Project>(projectsBoxName);
      final project = box.get(id);
      return Result.success(project);
    } catch (e) {
      return Result.error('Failed to get project: $e');
    }
  }

  static Future<Result<List<Project>, String>> getProjects() async {
    try {
      final box = Hive.box<Project>(projectsBoxName);
      final projects = box.values.toList();
      // Sort by updated date, newest first
      projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return Result.success(projects);
    } catch (e) {
      return Result.error('Failed to load projects: $e');
    }
  }

  static Future<Result<void, String>> deleteProject(String id) async {
    try {
      final box = Hive.box<Project>(projectsBoxName);
      await box.delete(id);
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to delete project: $e');
    }
  }
  
  static Future<Result<void, String>> deleteAllData() async {
    try {
      await Hive.deleteBoxFromDisk(projectsBoxName);
      await Hive.openBox<Project>(projectsBoxName);
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to delete all data: $e');
    }
  }
}
