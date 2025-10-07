import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_list_provider.dart';
import '../../data/models/project_model.dart';
import '../widgets/app_drawer.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

class ProjectListScreen extends ConsumerStatefulWidget {
  const ProjectListScreen({super.key});

  @override
  ConsumerState<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends ConsumerState<ProjectListScreen> {
  final _searchController = TextEditingController();
  ProjectStatus? _selectedStatus;
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectListProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    ref.read(projectListProvider.notifier).searchProjects(_searchController.text);
  }

  void _showSearchBar() {
    setState(() {
      _showSearchBar = true;
    });
    // Фокус на поиск
    Future.delayed(const Duration(milliseconds: 100), () {
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    });
  }

  void _hideSearchBar() {
    setState(() {
      _showSearchBar = false;
      _searchController.clear();
    });
    ref.read(projectListProvider.notifier).clearFilters();
  }

  void _onStatusFilterChanged(ProjectStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    ref.read(projectListProvider.notifier).filterByStatus(status);
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Status'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ProjectStatus.values
                .map((status) => RadioListTile<ProjectStatus>(
                      title: Text(status.value.replaceAll(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}').trim()),
                      value: status,
                      groupValue: _selectedStatus,
                      onChanged: (value) {
                        Navigator.pop(context);
                        _onStatusFilterChanged(value);
                      },
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onStatusFilterChanged(null);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectListState = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search projects...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
              )
            : const Text(AppConstants.appName),
        centerTitle: false,
        actions: _buildAppBarActions(projectListState),
        elevation: _showSearchBar ? 0 : 2,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(projectListProvider.notifier).refresh(),
        child: projectListState.when(
          data: (state) => _buildContent(state),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _buildErrorWidget(error.toString(), () {
            ref.read(projectListProvider.notifier).refresh();
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.goToCreateProject(),
        tooltip: 'Create New Project',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Widget> _buildAppBarActions(ProjectListState state) {
    final List<Widget> actions = [];

    if (_showSearchBar) {
      actions.add(IconButton(
        icon: const Icon(Icons.close),
        onPressed: _hideSearchBar,
      ));
    } else {
      actions.addAll([
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _showSearchBar,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.read(projectListProvider.notifier).refresh(),
        ),
        PopupMenuButton<String>(
          onSelected: (value) => _onAppAction(value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'clear_all', child: ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text('Clear All Projects'),
            )),
            const PopupMenuItem(value: 'export', child: ListTile(
              leading: Icon(Icons.download),
              title: Text('Export Data'),
            )),
          ],
        ),
      ]);
    }

    return actions;
  }

  void _onAppAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'export':
        _showExportOptions();
        break;
    }
  }

  Widget _buildContent(ProjectListState state) {
    if (state.isLoading && state.projects.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return _buildErrorWidget(state.error!, () {
        ref.read(projectListProvider.notifier).refresh();
      });
    }

    return Column(
      children: [
        // Header с статистикой
        _buildHeader(state),
        // Список
        Expanded(
          child: state.projects.isEmpty
              ? _buildEmptyState()
              : _buildProjectsList(state.projects),
        ),
      ],
    );
  }

  Widget _buildHeader(ProjectListState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Projects',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildStatChip(Icons.folder, '${state.totalCount} Total'),
                const SizedBox(width: 8),
                if (state.isFiltered)
                  _buildStatChip(Icons.filter_list, 'Active: ${state.filteredCount}'),
                if (_selectedStatus != null) ...[
                  const SizedBox(width: 8),
                  _buildStatusChip(_selectedStatus!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(ProjectStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.value.toUpperCase(),
            style: TextStyle(
              color: status.color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList(List<Project> projects) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: projects.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  Widget _buildProjectCard(Project project) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.goToProject(project.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Иконка статуса
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: project.status.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  project.status.icon,
                  color: project.status.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              // Основной контент
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (project.description.isNotEmpty) ...[
                      Text(
                        project.formattedDescription,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                    ],
                    Row(
                      children: [
                        Icon(Icons.description, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          project.filesCount,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          project.displayDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Действия
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _onProjectAction(value, project),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: const ListTile(
                      leading: Icon(Icons.edit),
                      title: Text('Edit TZ'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'duplicate',
                    child: const ListTile(
                      leading: Icon(Icons.content_copy),
                      title: Text('Duplicate'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'export_github',
                    child: const ListTile(
                      leading: Icon(Icons.cloud_upload),
                      title: Text('Export to GitHub'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onProjectAction(String action, Project project) {
    switch (action) {
      case 'edit':
        context.goToTzEditor(project.id);
        break;
      case 'duplicate':
        _duplicateProject(project);
        break;
      case 'export_github':
        context.goToGithubExport(project.id);
        break;
      case 'delete':
        _showDeleteDialog(project);
        break;
    }
  }

  void _duplicateProject(Project project) async {
    final newTitle = '${project.title} (Copy)';
    final result = await ref.read(projectListProvider.notifier).createProject(
      title: newTitle,
      description: project.description,
    );
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to duplicate: $error')),
      ),
      (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project duplicated successfully')),
      ),
    );
  }

  void _showDeleteDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.title}"?\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(projectListProvider.notifier).deleteProject(project.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted "${project.title}"')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              size: 96,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No Projects Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first creative project\nand start building with IdealCode!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.goToCreateProject(),
              icon: const Icon(Icons.add),
              label: const Text('Create First Project'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Projects'),
        content: const Text(
          'This will permanently delete ALL projects and data.\n\nThis action cannot be undone. Are you absolutely sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(projectListProvider.notifier).deleteAllProjects();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All projects cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Options'),
        content: const Text('Export your projects data (JSON format)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Реализация экспорта
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export functionality coming soon')),
              );
            },
            child: const Text('Export JSON'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(Icons.code, size: 48, color: AppConstants.primaryColor),
      applicationLegalese: '© 2024 IdealCode Team',
      children: [
        const Text('A mobile creative studio for AI-powered development.\n\n'
            'Create projects like an artist, let AI bots paint the code.'),
        const SizedBox(height: 16),
        const Text('Features:\n'
            '• Visual canvas for file management\n'
            '• PTZ import & parsing\n'
            '• GitHub integration\n'
            '• Offline storage with Hive'),
      ],
    );
  }
}
