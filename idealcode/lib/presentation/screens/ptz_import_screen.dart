import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../services/ptz_parser_service.dart';
import '../../utils/coordinate_calculator.dart';
import '../../data/models/project_file_model.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/result.dart';

class PtzImportScreen extends ConsumerStatefulWidget {
  const PtzImportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<PtzImportScreen> createState() => _PtzImportScreenState();
}

class _PtzImportScreenState extends ConsumerState<PtzImportScreen> {
  final _ptzController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isParsing = false;
  bool _isValid = false;
  String? _validationError;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _ptzController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _ptzController.removeListener(_onTextChanged);
    _ptzController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _ptzController.text.length;
    });

    // Автовалидация при изменении текста
    _validatePtz(_ptzController.text);
  }

  Future<void> _validatePtz(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _isValid = false;
        _validationError = null;
      });
      return;
    }

    final validationResult = PtzParserService.validatePTZ(text);
    validationResult.fold(
      (error) {
        setState(() {
          _isValid = false;
          _validationError = error.message;
        });
      },
      (validatedText) {
        setState(() {
          _isValid = true;
          _validationError = null;
        });
      },
    );
  }

  Future<void> _importPtz() async {
    if (!_formKey.currentState!.validate() || !_isValid || _isParsing) return;

    final notifier = ref.read(projectProvider(widget.projectId).notifier);
    setState(() {
      _isParsing = true;
    });

    final parseResult = PtzParserService.parsePTZ(_ptzController.text);

    parseResult.fold(
      (error) {
        setState(() {
          _isParsing = false;
          _validationError = error.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parse error: ${error.message}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      (files) async {
        // Расчет позиций
        final positionedFiles = CoordinateCalculator.calculateGridPositions(files);
        await notifier.addFiles(positionedFiles);

        setState(() {
          _isParsing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported ${files.length} files successfully!'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'View Canvas',
                onPressed: () => context.goToProject(widget.projectId),
              ),
            ),
          );
        }

        // Очистка поля после успешного импорта
        _ptzController.clear();
        _validatePtz('');
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import PTZ'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isValid)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showPtzFormatHelp,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Инструкция
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lightbulb_outline, color: Colors.blue),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Paste your complete PTZ text below. It should follow this format:\n'
                              '📂 ЭТАП 1: CONFIGURATION\n'
                              '1. Файл: path/to/pubspec.yaml\n'
                              'Аннотация: Description here.\n'
                              'Связи: Depends on file 2.\n\n'
                              'The parser will automatically extract files, descriptions, and dependencies.',
                              style: TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _showPtzFormatHelp,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Show PTZ Format Guide'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // TextField для PTZ
              TextFormField(
                controller: _ptzController,
                maxLines: 20,
                minLines: 10,
                expands: false,
                decoration: InputDecoration(
                  labelText: 'PTZ Content *',
                  hintText: 'Paste your detailed technical specification here...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _isValid ? Colors.green : Colors.orange),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'PTZ content is required';
                  }
                  if (!_isValid) {
                    return 'Please fix the format (check validation below)';
                  }
                  return null;
                },
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 8),

              // Счетчик и валидация
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isValid ? Colors.green.withOpacity(0.1) : 
                           (_validationError != null ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isValid ? Colors.green : 
                           (_validationError != null ? Colors.red : Colors.grey),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isValid ? Icons.check_circle : 
                             (_validationError != null ? Icons.error : Icons.info),
                      color: _isValid ? Colors.green : 
                             (_validationError != null ? Colors.red : Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_charCount > 0 ? '$_charCount chars' : 'Enter PTZ content'}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (_validationError != null)
                            Text(
                              _validationError!,
                              style: const TextStyle(color: Colors.red, fontSize: 12),
                            ),
                          if (_isValid)
                            Text(
                              'Format is valid! Ready to parse.',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Кнопки действий
              if (_isParsing)
                const Center(child: CircularProgressIndicator())
              else ...[
                ElevatedButton.icon(
                  onPressed: _isValid ? _importPtz : null,
                  icon: const Icon(Icons.upload),
                  label: const Text('Parse & Import Files'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _clearAndValidate,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear & Validate'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showExamplePtz,
                    icon: const Icon(Icons.help_outline),
                    label: const Text('Load Example PTZ'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showPtzFormatHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PTZ Format Guide'),
        content: const SingleChildScrollView(
          child: Text(
            'Your PTZ should follow this structure:\n\n'
            '📂 STAGE 1: CONFIGURATION FILES\n'
            '1. File: pubspec.yaml\n'
            'Annotation: Main Flutter config file with dependencies.\n'
            'Connections: Depends on analysis_options.yaml (file 2).\n\n'
            '📂 STAGE 2: MODELS\n'
            '2. File: lib/models/user.dart\n'
            'Annotation: User data model.\n'
            'Connections: Used by screens (files 5-7).\n\n'
            'Key points:\n'
            '• Use numbers for file ordering (1., 2., etc.)\n'
            '• "File:" followed by path (e.g., lib/main.dart)\n'
            '• "Annotation:" for description\n'
            '• "Connections:" for dependencies (mention file numbers or paths)\n'
            '• Stages with 📂 for grouping\n\n'
            'The parser auto-detects files, types, and dependencies!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showExamplePtz() {
    const example = '''
📂 ЭТАП 1: КОНФИГУРАЦИЯ ПРОЕКТА
1. Файл: pubspec.yaml
Аннотация: Основной конфигурационный файл Flutter. Определяет зависимости, версии SDK и метаданные проекта. Включает пакеты для Riverpod, Hive и GitHub API.
Связи: Родитель для файла 2 (analysis_options.yaml) и файла 6 (lib/main.dart).

2. Файл: analysis_options.yaml
Аннотация: Настройки статического анализа и линтинга. Включает правила для чистоты кода и Flutter lint.
Связи: Глобальные настройки, влияют на весь проект, особенно на файлы в lib/.

📂 ЭТАП 2: ОСНОВНАЯ СТРУКТУРА
3. Файл: lib/main.dart
Аннотация: Точка входа в приложение. Инициализирует Hive, провайдеры и запускает App.
Связи: Зависит от файла 4 (app.dart), используется всеми экранами.

4. Файл: lib/app.dart
Аннотация: Основной виджет приложения с роутингом GoRouter и темой Material Design.
Связи: Включает экраны 18-25, зависит от constants (5).
    ''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Example PTZ'),
        content: SingleChildScrollView(child: Text(example)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _ptzController.text = example;
              _validatePtz(example);
            },
            child: const Text('Load Example'),
          ),
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _clearAndValidate() {
    _ptzController.clear();
    setState(() {
      _validationError = null;
      _isValid = false;
    });
    _validatePtz('');
  }
}
