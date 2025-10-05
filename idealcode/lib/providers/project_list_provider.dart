import 'package:riverpod/riverpod.dart';

import '../data/models/project_model.dart';
import '../services/storage_service.dart';

class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    return _loadProjects();
  }

  Future<List<Project>> _loadProjects() async {
    final result = await StorageService.getProjects();
    return result.fold(
      (error) => throw Exception(error),
      (projects) => projects,
    );
  }

  Future<void> createProject({required String title, String? description}) async {
    final newProject = Project(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    state = const AsyncValue.loading();
    final saveResult = await StorageService.saveProject(newProject);
    
    final currentProjects = await _loadProjects();
    state = saveResult.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => AsyncValue.data(currentProjects),
    );
  }

  Future<void> deleteProject(String id) async {
    state = const AsyncValue.loading();
    final deleteResult = await StorageService.deleteProject(id);
    
    final currentProjects = await _loadProjects();
    state = deleteResult.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => AsyncValue.data(currentProjects),
    );
  }

  Future<void> deleteAllProjects() async {
    state = const AsyncValue.loading();
    final deleteResult = await StorageService.deleteAllData();
    final currentProjects = await _loadProjects();
    state = deleteResult.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => AsyncValue.data(currentProjects),
    );
  }
}

final projectListProvider =
    AsyncNotifierProvider<ProjectListNotifier, List<Project>>(
  ProjectListNotifier.new,
);
