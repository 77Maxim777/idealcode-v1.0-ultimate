import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../data/models/project_file_model.dart';
import '../../services/syntax_highlighter.dart';
import '../../core/constants/app_constants.dart';

class CodeEditorScreen extends ConsumerStatefulWidget {
  const CodeEditorScreen({
    super.key,
    required this.projectId,
    required this.fileId,
  });

  final String projectId;
  final String fileId;

  @override
  ConsumerState<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends ConsumerState<CodeEditorScreen> {
  late TextEditingController _editorController;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController();
    _loadFileContent();
    _editorController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _editorController.removeListener(_onTextChanged);
    _editorController.dispose();
    super.dispose();
  }

  void _loadFileContent() {
    final projectState = ref.read(projectProvider(widget.projectId));
    if (projectState is AsyncData<ProjectState>) {
      final file = projectState.value.project.getFileById(widget.fileId);
      _editorController.text = file?.content ?? '';
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveContent() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    final notifier = ref.read(projectProvider(widget.projectId).notifier);
    await notifier.updateFileContent(widget.fileId, _editorController.text);

    setState(() {
      _hasUnsavedChanges = false;
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectStateAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Code Editor'),
        actions: [
          IconButton(
            icon: Icon(
              _hasUnsavedChanges ? Icons.save : Icons.save_alt,
              color: _hasUnsavedChanges ? Colors.red : Colors.green,
            ),
            onPressed: _saveContent,
            tooltip: 'Save Changes',
          ),
        ],
      ),
      body: projectStateAsync.when(
        data: (state) {
          final file = state.project.getFileById(widget.fileId);
          if (file == null) return const Center(child: Text('File not found'));

          return Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _editorController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Start writing your code here...',
                    ),
                    onTap: () {
                      _loadFileContent(); // Reload on tap
                    },
                  ),
                ),
              ),
              if (_hasUnsavedChanges) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(width: 12),
                      const Text('Changes unsaved!'),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
