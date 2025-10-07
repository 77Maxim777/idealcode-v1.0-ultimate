import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../data/models/project_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

class TzEditorScreen extends ConsumerStatefulWidget {
  const TzEditorScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<TzEditorScreen> createState() => _TzEditorScreenState();
}

class _TzEditorScreenState extends ConsumerState<TzEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _saveAnimationController;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;
  Timer? _autoSaveTimer;
  final int _autoSaveDelay = 2000; // 2 секунды

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _saveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Загружаем ТЗ при инициализации
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTz());

    // Слушатель изменений
    _controller.addListener(_onTextChanged);

    // Автозапуск анимации сохранения
    _saveAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _saveAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  void _loadTz() {
    final stateAsync = ref.read(projectProvider(widget.projectId));
    if (stateAsync is AsyncData<ProjectState>) {
      final description = stateAsync.value.project.description;
      _controller.text = description;
      _hasUnsavedChanges = false;
    }
  }

  void _onTextChanged() {
    setState(() {
      _hasUnsavedChanges = true;
    });

    // Автосохранение
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(Duration(milliseconds: _autoSaveDelay), _autoSave);
  }

  Future<void> _autoSave() async {
    if (!_hasUnsavedChanges || _isSaving) return;

    await _saveTz();
  }

  Future<void> _saveTz() async {
    if (_controller.text == ref.read(projectProvider(widget.projectId)).valueOrNull?.project.description) {
      _hasUnsavedChanges = false;
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final notifier = ref.read(projectProvider(widget.projectId).notifier);
    await notifier.updateDescription(_controller.text);

    setState(() {
      _hasUnsavedChanges = false;
      _isSaving = false;
    });

    _saveAnimationController.forward();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('TZ saved automatically'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('TZ copied to clipboard'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _shareTz() async {
    // Используем share_plus для мобильного шаринга
    if (_controller.text.isEmpty) return;

    // TODO: Интеграция share_plus
    await _copyToClipboard();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shared via clipboard (integration coming soon)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectStateAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Specification (TZ)'),
        actions: [
          // Копировать
          AnimatedBuilder(
            animation: _saveAnimationController,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  Icons.copy,
                  color: _saveAnimationController.value > 0 ? Colors.green : null,
                ),
                onPressed: _copyToClipboard,
                tooltip: 'Copy TZ',
              );
            },
          ),
          // Поделиться
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTz,
            tooltip: 'Share TZ',
          ),
          // Сохранить
          if (_hasUnsavedChanges)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveTz,
              tooltip: 'Save TZ',
            ),
        ],
      ),
      body: projectStateAsync.when(
        data: (state) => _buildEditor(state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load TZ: $error'),
              ElevatedButton(
                onPressed: () => ref.invalidate(projectProvider(widget.projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(ProjectState state) {
    return Column(
      children: [
        // Header с информацией о проекте
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    state.project.status.icon,
                    color: state.project.status.color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.project.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_hasUnsavedChanges)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Unsaved', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Your artistic vision for AI development. Bots will follow this blueprint.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              const SizedBox(height: 8),
              // Счетчик символов
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Character count: ${_controller.text.length}/10000',
                    style: TextStyle(
                      color: _controller.text.length > 9000 ? Colors.red : Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  if (_autoSaveTimer?.isActive ?? false)
                    const Text(
                      'Auto-saving...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Редактор
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                fontFamily: 'Roboto',
              ),
              decoration: InputDecoration(
                hintText: 'Describe your project\'s concept, goals, target audience, and key features. '
                    'Be creative - this is the soul of your digital masterpiece.\n\n'
                    'Example:\n'
                    '• Overall Vision: A mobile app that...\n'
                    '• Main Features: User authentication, AI integration...\n'
                    '• Technical Requirements: Flutter, Firebase, Offline support...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _hasUnsavedChanges 
                        ? Colors.orange 
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.orange, width: 2),
                ),
                contentPadding: const EdgeInsets.all(16),
                fillColor: Colors.transparent,
                filled: false,
              ),
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              onTap: () => _focusNode.requestFocus(),
              onEditingComplete: _focusNode.unfocus,
            ),
          ),
        ),
        // Футер с действиями
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _hasUnsavedChanges ? _saveTz : null,
                  icon: _isSaving 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_hasUnsavedChanges ? 'Save TZ' : 'Saved'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareTz,
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
