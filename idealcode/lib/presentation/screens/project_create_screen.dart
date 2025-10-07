import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_list_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

class ProjectCreateScreen extends ConsumerStatefulWidget {
  const ProjectCreateScreen({super.key});

  @override
  ConsumerState<ProjectCreateScreen> createState() => _ProjectCreateScreenState();
}

class _ProjectCreateScreenState extends ConsumerState<ProjectCreateScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isCreating = false;
  bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_validateForm);
    _descriptionController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {}); // Обновляем UI для валидации
  }

  bool get _isFormValid {
    return _titleController.text.trim().isNotEmpty &&
           _titleController.text.trim().length >= 3 &&
           !_isCreating;
  }

  Future<void> _createProject({bool navigateToPtzImport = false}) async {
    if (!_isFormValid || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid project title (min 3 characters)')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final result = await ref.read(projectListProvider.notifier).createProject(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isCreating = false;
      });

      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create project: $error')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project created successfully!')),
          );

          if (navigateToPtzImport) {
            // Переходим к импорту ПТЗ для последнего созданного проекта
            final projects = ref.read(projectListProvider).valueOrNull?.projects ?? [];
            if (projects.isNotEmpty) {
              final newProjectId = projects.first.id; // Последний по дате
              context.goToPtzImport(newProjectId);
            } else {
              context.goToHome();
            }
          } else {
            context.goToHome();
          }
        },
      );
    }
  }

  Future<void> _saveAsDraft() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least enter a title to save as draft')),
      );
      return;
    }

    await _createProject();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Project'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goToHome(),
        ),
        actions: [
          TextButton(
            onPressed: _isCreating ? null : _saveAsDraft,
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Project Title *',
                  hintText: 'Enter a creative name for your project (e.g., "My AI App")',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
                autofocus: true,
                maxLength: 100,
              ),
              const SizedBox(height: 24),

              // Description (TZ) field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description / Technical Specification (TZ)',
                  hintText: 'Describe your project vision, goals, and key features. This is your creative blueprint for AI bots.',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                expands: false,
                validator: (value) {
                  if (value != null && value.length > 5000) {
                    return 'Description too long (max 5000 chars)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'This is your TZ - the artistic vision for your project. AI bots will use it as guidance.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Character counter for description
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${_descriptionController.text.length}/5000',
                  style: TextStyle(
                    color: _descriptionController.text.length > 4500 
                        ? Colors.red 
                        : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Actions
              if (_isCreating)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Primary button
                ElevatedButton.icon(
                  onPressed: _isFormValid ? () => _createProject(navigateToPtzImport: false) : null,
                  icon: const Icon(Icons.create_new_folder),
                  label: const Text('Create Project'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Secondary button for PTZ import
                OutlinedButton.icon(
                  onPressed: _isFormValid ? () => _createProject(navigateToPtzImport: true) : null,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Create & Import PTZ'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Info about next steps
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'What\'s Next?',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. After creation, you\'ll see the canvas.\n'
                        '2. Use "Import PTZ" to add file structure.\n'
                        '3. Edit TZ for AI guidance.\n'
                        '4. Drag files on canvas to organize.\n'
                        '5. Export to GitHub when ready!',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
