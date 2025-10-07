import 'package:riverpod/riverpod.dart';

import '../data/models/project_model.dart';
import '../data/models/project_file_model.dart';
import '../services/storage_service.dart';
import '../utils/result.dart';

/// Состояние одного проекта
class ProjectState {
  final Project project;
  final bool isLoading;
  final String? error;

  const ProjectState({
    required this.project,
    this.isLoading = false,
    this.error,
  });

  ProjectState copyWith({
    Project? project,
    bool? isLoading,
    String? error,
  }) {
    return ProjectState(
      project: project ?? this.project,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get hasError => error != null;
  bool get hasFiles => project.files.isNotEmpty;
}

/// AsyncNotifier для управления состоянием одного проекта
class ProjectNotifier extends AsyncNotifier<ProjectState> {
  late String _projectId;

  @override
  Future<ProjectState> build(String projectId) async {
    _projectId = projectId;
    return await _loadProject();
  }

  /// Загрузка проекта из хранилища
  Future<ProjectState> _loadProject() async {
    final result = await StorageService.getProject(_projectId);
    return result.fold(
      (error) => ProjectState(
        project: Project(
          id: _projectId,
          title: 'Untitled',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        error: error,
      ),
      (project) => ProjectState(
        project: project ?? Project(
          id: _projectId,
          title: 'Untitled',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
  }

  /// Обновление содержимого файла
  Future<void> updateFileContent(String fileId, String content) async {
    state = const AsyncValue.loading().copyWith(
      value: state.value?.copyWith(isLoading: true),
    );

    final currentState = state.value;
    if (currentState == null) return;

    final file = currentState.project.getFileById(fileId);
    if (file == null) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'File not found',
        isLoading: false,
      ));
      return;
    }

    final updatedFile = file.updateContent(content);
    final updatedProject = currentState.project.updateFile(fileId, updatedFile);

    final saveResult = await StorageService.saveProject(updatedProject);

    saveResult.fold(
      (error) => state = AsyncValue.data(currentState.copyWith(
        error: error,
        isLoading: false,
      )),
      (_) => state = AsyncValue.data(currentState.copyWith(
        project: updatedProject,
        error: null,
        isLoading: false,
      )),
    );
  }

  /// Перемещение файла на холсте
  Future<void> updateFilePosition(String fileId, double x, double y) async {
    final currentState = state.value;
    if (currentState == null) return;

    final file = currentState.project.getFileById(fileId);
    if (file == null) return;

    final updatedFile = file.updatePosition(x, y);
    final updatedProject = currentState.project.updateFile(fileId, updatedFile);

    // Обновляем состояние сразу для плавности UI
    state = AsyncValue.data(currentState.copyWith(
      project: updatedProject,
      isLoading: false,
    ));

    // Сохраняем в фоне
    StorageService.saveProject(updatedProject).ignore();
  }

  /// Добавление файлов из ПТЗ
  Future<void> addFiles(List<ProjectFile> newFiles) async {
    state = const AsyncValue.loading().copyWith(
      value: state.value?.copyWith(isLoading: true),
    );

    final currentState = state.value;
    if (currentState == null) return;

    // Проверяем дубликаты по пути
    final existingPaths = currentState.project.files
        .map((f) => f.path.toLowerCase())
        .toSet();

    final uniqueNewFiles = newFiles.where((file) =>
      !existingPaths.contains(file.path.toLowerCase())
    ).toList();

    if (uniqueNewFiles.isEmpty) {
      state = AsyncValue.data(currentState.copyWith(
        error: 'No new files to add',
        isLoading: false,
      ));
      return;
    }

    final allFiles = [...currentState.project.files, ...uniqueNewFiles];
    final updatedProject = currentState.project.copyWithUpdatedFiles(allFiles);

    final saveResult = await StorageService.saveProject(updatedProject);

    saveResult.fold(
      (error) => state = AsyncValue.data(currentState.copyWith(
        error: error,
        isLoading: false,
      )),
      (_) => state = AsyncValue.data(currentState.copyWith(
        project: updatedProject,
        error: null,
        isLoading: false,
      )),
    );
  }

  /// Обновление описания (ТЗ)
  Future<void> updateDescription(String description) async {
    state = const AsyncValue.loading().copyWith(
      value: state.value?.copyWith(isLoading: true),
    );

    final currentState = state.value;
    if (currentState == null) return;

    final updatedProject = currentState.project.copyWith(
      description: description.trim(),
      updatedAt: DateTime.now(),
      status: ProjectStatus.inProgress,
    );

    final saveResult = await StorageService.saveProject(updatedProject);

    saveResult.fold(
      (error) => state = AsyncValue.data(currentState.copyWith(
        error: error,
        isLoading: false,
      )),
      (_) => state = AsyncValue.data(currentState.copyWith(
        project: updatedProject,
        error: null,
        isLoading: false,
      )),
    );
  }

  /// Обновление статуса проекта
  Future<void> updateProjectStatus(ProjectStatus status) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedProject = currentState.project.copyWith(
      status: status,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(currentState.copyWith(
      project: updatedProject,
      isLoading: false,
    ));

    StorageService.saveProject(updatedProject).ignore();
  }

  /// Перезагрузка проекта
  Future<void> refresh() async {
    final newState = await _loadProject();
    state = AsyncValue.data(newState);
  }

  /// Удаление файла
  Future<void> deleteFile(String fileId) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedFiles = currentState.project.files
        .where((file) => file.id != fileId)
        .toList();

    final updatedProject = currentState.project.copyWithUpdatedFiles(updatedFiles);

    state = AsyncValue.data(currentState.copyWith(
      project: updatedProject,
      isLoading: false,
    ));

    StorageService.saveProject(updatedProject).ignore();
  }
}

/// Провайдер для конкретного проекта (family для ID)
final projectProvider = AsyncNotifierProvider.family<ProjectNotifier, ProjectState, String>(
  () => ProjectNotifier(),
);
