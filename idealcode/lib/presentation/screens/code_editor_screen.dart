import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../data/models/project_file_model.dart';
import '../../services/syntax_highlighter.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/coordinate_calculator.dart';
import '../../core/router/app_router.dart';

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

class _CodeEditorScreenState extends ConsumerState<CodeEditorScreen>
    with TickerProviderStateMixin {
  late TextEditingController _editorController;
  late TextEditingController _previewController;
  late FocusNode _focusNode;
  bool _showPreview = true;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  late AnimationController _saveAnimationController;
  late Animation<double> _fadeAnimation;
  String? _currentContent;
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    _editorController = TextEditingController();
    _previewController = TextEditingController();
    _focusNode = FocusNode();
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0)
        .animate(CurvedAnimation(parent: _saveAnimationController, curve: Curves.easeInOut));

    // Загружаем контент при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFileContent());

    _editorController.addListener(_onTextChanged);
    _saveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _saveAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _editorController.removeListener(_onTextChanged);
    _editorController.dispose();
    _previewController.dispose();
    _focusNode.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  void _loadFileContent() {
    final stateAsync = ref.read(projectProvider(widget.projectId));
    if (stateAsync is AsyncData<ProjectState>) {
      final file = stateAsync.value.project.getFileById(widget.fileId);
      if (file != null) {
        _currentContent = file.content;
        _editorController.text = file.content;
        _updatePreview();
        _updateLineCount();
        _hasUnsavedChanges = false;
      }
    }
  }

  void _onTextChanged() {
    _hasUnsavedChanges = _editorController.text != _currentContent;
    _updatePreview();
    _updateLineCount();
    setState(() {});
  }

  void _updatePreview() {
    _previewController.text = _editorController.text;
  }

  void _updateLineCount() {
    _lineCount = _editorController.text.split('\n').length;
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
      _currentContent = _editorController.text;
    });

    _saveAnimationController.forward();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File saved!'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _togglePreview() {
    setState(() {
      _showPreview = !_showPreview;
    });
  }

  void _onFieldTap() {
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final projectStateAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.code,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Code Editor',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  StreamBuilder<int>(
                    stream: Stream.periodic(Duration(milliseconds: 500)).asyncMap((_) => _lineCount),
                    builder: (context, snapshot) => Text(
                      '${snapshot.data ?? _lineCount} lines | ${_editorController.text.length} chars',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.preview : Icons.edit),
            onPressed: _togglePreview,
            tooltip: _showPreview ? 'Hide Preview' : 'Show Preview',
          ),
          if (_hasUnsavedChanges)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveContent,
              tooltip: 'Save File',
            ),
        ],
      ),
      body: projectStateAsync.when(
        data: (state) => _buildEditorBody(state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading file: $error'),
              ElevatedButton(
                onPressed: _loadFileContent,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _hasUnsavedChanges
          ? FloatingActionButton.extended(
              onPressed: _saveContent,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildEditorBody(ProjectState state) {
    final file = state.project.getFileById(widget.fileId);
    if (file == null) {
      return const Center(child: Text('File not found'));
    }

    return Row(
      children: [
        // Редактор (левая панель)
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Заголовок файла
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    Icon(
                      file.type.icon,
                      color: file.type.color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.displayName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (file.annotation.isNotEmpty)
                      Tooltip(
                        message: file.annotation,
                        child: const Icon(Icons.info_outline, size: 20),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.background,
                  child: GestureDetector(
                    onTap: _onFieldTap,
                    child: TextField(
                      controller: _editorController,
                      focusNode: _focusNode,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 13,
                        backgroundColor: Colors.transparent,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Start editing your code...',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Разделитель
        if (_showPreview) ...[
          Container(
            width: 1,
            height: double.infinity,
            color: Theme.of(context).colorScheme.outline,
            margin: const EdgeInsets.symmetric(vertical: 16),
          ),
          // Превью (правая панель)
          Expanded(
            flex: 1,
            child: Column(
              children: [
                // Заголовок превью
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      const Icon(Icons.preview, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Syntax Preview', style: TextStyle(fontWeight: FontWeight.bold))),
                      _buildLineNumberIndicator(),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.05),
                    child: SingleChildScrollView(
                      child: HighlightView(
                        _previewController.text.isEmpty ? '// No content to preview\n// Start typing code above' : _previewController.text,
                        language: SyntaxHighlighter.getLanguage(file.path),
                        theme: vs2015Theme,
                        padding: const EdgeInsets.all(16),
                        textStyle: const TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLineNumberIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _hasUnsavedChanges ? Colors.orange.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasUnsavedChanges ? Icons.circle : Icons.check_circle_outline,
            size: 12,
            color: _hasUnsavedChanges ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 4),
          Text(
            'L$_lineCount',
            style: TextStyle(
              fontSize: 12,
              color: _hasUnsavedChanges ? Colors.orange : Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
