import 'package:riverpod/riverpod.dart';

import '../data/models/project_file_model.dart';
import '../data/models/project_model.dart';
import '../services/storage_service.dart';
import '../utils/result.dart';

class ProjectNotifier extends AsyncNotifier<ProjectState> {
  late String _projectId;

  @override
  Future<ProjectState> build(String projectId) async {
    _projectId = projectId;
    final result = await StorageService.getProject(projectId);
    return result.fold(
      (error) => throw Exception(error),
      (project) {
        if (project == null) {
          throw Exception('Project not found');
        }
        return ProjectState(project: project);
      },
    );
  }

  Future<void> updateFileContent(String fileId, String content) async {
    final project = state.value!.project;
    final updatedFiles = project.files.map((file) {
      if (file.id == fileId) {
        return file.copyWith(
          content: content,
          status: content.isEmpty ? FileStatus.empty : FileStatus.completed,
          lastModified: DateTime.now(),
        );
      }
      return file;
    }).toList();

    final updatedProject = project.copyWith(
      files: updatedFiles,
      updatedAt: DateTime.now(),
      status: ProjectStatus.inProgress,
    );

    state = const AsyncValue.loading();
    final saveResult = await StorageService.saveProject(updatedProject);
    state = saveResult.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => AsyncValue.data(state.value!.copyWith(project: updatedProject)),
    );
  }

  Future<void> updateFilePosition(String fileId, double x, double y) async {
    final project = state.value!.project;
    final updatedFiles = project.files.map((file) {
      if (file.id == fileId) {
        return file.copyWith(x: x, y: y);
      }
      return file;
    }).toList();

    final updatedProject = project.copyWith(files: updatedFiles);
    state = AsyncValue.data(state.value!.copyWith(project: updatedProject));
    await StorageService.saveProject(updatedProject);
  }

  Future<void> addFiles(List<ProjectFile> newFiles) async {
    final project = state.value!.project;
    final updatedProject = project.copyWith(
      files: [...project.files, ...newFiles],
      updatedAt: DateTime.now(),
      status: ProjectStatus.inProgress,
    );
    state = const AsyncValue.loading();
    final saveResult = await StorageService.saveProject(updatedProject);
    state = saveResult.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => AsyncValue.data(state.value!.copyWith(project: updatedProject)),
    );
  }

  Future<void> updateDescription(String description) async {
    final project = state.value!.project;
    final updatedProject = project.copyWith(
      description: description,
      updatedAt: DateTime.now(),
    );
    
    state = const AsyncValue.loading();
    final saveResult = await StorageService.saveProject(updatedProject);
    state = saveResult.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (_) => AsyncValue.data(state.value!.copyWith(project: updatedProject)),
    );
  }
}

class ProjectState {
  final Project project;

  ProjectState({required this.project});
}

final projectProvider =
    AsyncNotifierProvider.family<ProjectNotifier, ProjectState, String>(
  ProjectNotifier.new,
);
