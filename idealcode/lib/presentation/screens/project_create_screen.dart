import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_list_provider.dart';
import '../widgets/app_drawer.dart';

class ProjectCreateScreen extends ConsumerStatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  ConsumerState<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends ConsumerState<ProjectCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject({bool navigateToImport = false}) async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    await ref.read(projectListProvider.notifier).createProject(
          title: _titleController.text,
          description: _descriptionController.text,
        );

    if (mounted) {
      setState(() {
        _isCreating = false;
      });

      if (navigateToImport) {
        // Get the newly created project
        final projects = ref.read(projectListProvider).value;
        if (projects != null && projects.isNotEmpty) {
          final newProject = projects.first; // Projects are sorted by updated date
          context.go('/project/${newProject.id}/import-ptz');
        } else {
          context.pop();
        }
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
      ),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const Spacer(),
            if (_isCreating)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: () => _createProject(),
                child: const Text('Create Project'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => _createProject(navigateToImport: true),
                child: const Text('Create and Import PTZ'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
