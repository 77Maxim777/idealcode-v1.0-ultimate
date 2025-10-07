import 'package:riverpod/riverpod.dart';

import '../data/models/project_model.dart';
import '../services/storage_service.dart';
import '../utils/result.dart';

/// Состояние списка проектов
class ProjectListState {
  final List<Project> projects;
  final bool isLoading;
  final String? searchQuery;
  final ProjectStatus? filterStatus;
  final String? error;
  final int totalCount;
  final int filteredCount;

  const ProjectListState({
    this.projects = const [],
    this.isLoading = false,
    this.searchQuery,
    this.filterStatus,
    this.error,
    required this.totalCount,
    required this.filteredCount,
  });

  ProjectListState copyWith({
    List<Project>? projects,
    bool? isLoading,
    String? searchQuery,
    ProjectStatus? filterStatus,
    String? error,
    int? totalCount,
    int? filteredCount,
  }) {
    return ProjectListState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
      error: error ?? this.error,
      totalCount: totalCount ?? this.totalCount,
      filteredCount: filteredCount ?? this.filteredCount,
    );
  }

  bool get isEmpty => filteredCount == 0;
  bool get hasError => error != null;
  bool get isFiltered => searchQuery != null || filterStatus != null;
}

/// AsyncNotifier для управления списком проектов
class ProjectListNotifier extends AsyncNotifier<ProjectListState> {
  @override
  Future<ProjectListState> build() async {
    return await _loadProjects();
  }

  /// Загрузка проектов с фильтрами
  Future<ProjectListState> _loadProjects() async {
    final result = await StorageService.getProjects(
      status: state.value?.filterStatus,
    );

    return result.fold(
      (error) => ProjectListState(
        error: error,
        totalCount: 0,
        filteredCount: 0,
      ),
      (allProjects) {
        List<Project> filteredProjects = allProjects;

        // Поиск
        final query = state.value?.searchQuery;
        if (query != null && query!.isNotEmpty) {
          filteredProjects = filteredProjects.where((project) {
            final lowerQuery = query.toLowerCase();
            return project.title.toLowerCase().contains(lowerQuery) ||
                   project.description.toLowerCase().contains(lowerQuery) ||
                   project.files.any((file) =>
                     file.displayName.toLowerCase().contains(lowerQuery));
          }).toList();
        }

        // Фильтр по статусу (если не применен в StorageService)
        final status = state.value?.filterStatus;
        if (status != null) {
          filteredProjects = filteredProjects
              .where((p) => p.status.value == status.value)
              .toList();
        }

        // Сортировка по дате обновления
        filteredProjects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return ProjectListState(
          projects: filteredProjects,
          totalCount: allProjects.length,
          filteredCount: filteredProjects.length,
          searchQuery: state.value?.searchQuery,
          filterStatus: state.value?.filterStatus,
        );
      },
    );
  }

  /// Создание нового проекта
  Future<void> createProject({
    required String title,
    String? description,
  }) async {
    if (title.trim().isEmpty) {
      state = AsyncValue.data(state.value!.copyWith(
        error: 'Project title cannot be empty',
      ));
      return;
    }

    state = const AsyncValue.loading().copyWith(
      value: state.value?.copyWith(isLoading: true, error: null),
    );

    final result = await StorageService.createProject(
      title: title.trim(),
      description: description?.trim(),
    );

    result.fold(
      (error) => state = AsyncValue.data(state.value!.copyWith(
        error: error,
        isLoading: false,
      )),
      (_) async {
        final newState = await _loadProjects();
        state = AsyncValue.data(newState.copyWith(isLoading: false));
      },
    );
  }

  /// Удаление проекта
  Future<void> deleteProject(String projectId) async {
    state = const AsyncValue.loading().copyWith(
      value: state.value?.copyWith(isLoading: true, error: null),
    );

    final result = await StorageService.deleteProject(projectId);

    result.fold(
      (error) => state = AsyncValue.data(state.value!.copyWith(
        error: error,
        isLoading: false,
      )),
      (_) async {
        final newState = await _loadProjects();
        state = AsyncValue.data(newState.copyWith(isLoading: false));
      },
    );
  }

  /// Удаление всех проектов
  Future<void> deleteAllProjects() async {
    state = const AsyncValue.loading().copyWith(
      value: state.value?.copyWith(isLoading: true, error: null),
    );

    final result = await StorageService.deleteAllProjects();

    result.fold(
      (error) => state = AsyncValue.data(state.value!.copyWith(
        error: error,
        isLoading: false,
      )),
      (count) async {
        final newState = await _loadProjects();
        state = AsyncValue.data(newState.copyWith(isLoading: false));
      },
    );
  }

  /// Поиск проектов
  Future<void> searchProjects(String query) async {
    final currentState = state.value!;
    final newState = currentState.copyWith(searchQuery: query.trim());

    state = AsyncValue.data(newState);

    // Задержка для debounce, но в простом случае просто загружаем
    await Future.delayed(const Duration(milliseconds: 300));
    await _loadProjectsWithState(newState);
  }

  /// Фильтрация по статусу
  Future<void> filterByStatus(ProjectStatus? status) async {
    final currentState = state.value!;
    final newState = currentState.copyWith(filterStatus: status);

    state = AsyncValue.data(newState);
    await _loadProjectsWithState(newState);
  }

  /// Очистка фильтров
  Future<void> clearFilters() async {
    final newState = state.value!.copyWith(
      searchQuery: null,
      filterStatus: null,
    );

    state = AsyncValue.data(newState);
    await _loadProjectsWithState(newState);
  }

  /// Приватный метод для загрузки с текущим состоянием
  Future<void> _loadProjectsWithState(ProjectListState newState) async {
    state = const AsyncValue.loading().copyWith(value: newState.copyWith(isLoading: true));

    final allProjectsResult = await StorageService.getProjects();
    allProjectsResult.fold(
      (error) => state = AsyncValue.data(newState.copyWith(
        error: error,
        isLoading: false,
        projects: [],
        filteredCount: 0,
      )),
      (allProjects) {
        // Применяем фильтры локально
        List<Project> filtered = allProjects;

        if (newState.searchQuery != null && newState.searchQuery!.isNotEmpty) {
          final lowerQuery = newState.searchQuery!.toLowerCase();
          filtered = filtered.where((project) {
            return project.title.toLowerCase().contains(lowerQuery) ||
                   project.description.toLowerCase().contains(lowerQuery) ||
                   project.files.any((file) =>
                     file.displayName.toLowerCase().contains(lowerQuery));
          }).toList();
        }

        if (newState.filterStatus != null) {
          filtered = filtered
              .where((p) => p.status.value == newState.filterStatus!.value)
              .toList();
        }

        filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        state = AsyncValue.data(newState.copyWith(
          projects: filtered,
          totalCount: allProjects.length,
          filteredCount: filtered.length,
          isLoading: false,
        ));
      },
    );
  }

  /// Перезагрузка списка
  Future<void> refresh() async {
    final newState = await _loadProjects();
    state = AsyncValue.data(newState);
  }
}

/// Провайдер для списка проектов
final projectListProvider = AsyncNotifierProvider<ProjectListNotifier, ProjectListState>(
  () => ProjectListNotifier(),
);
