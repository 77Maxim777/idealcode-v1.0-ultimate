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
  String? _validationError;

  @override
  void dispose() {
    _ptzController.dispose();
    super.dispose();
  }

  Future<void> _importPtz() async {
    if (!_formKey.currentState!.validate() || _isParsing) return;

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
          SnackBar(content: Text('Parse error: ${error.message}')),
        );
      },
      (files) async {
        // Расчет и сохранение позиций
        final positionedFiles = CoordinateCalculator.calculateGridPositions(files);
        await ref.read(projectProvider(widget.projectId).notifier).addFiles(positionedFiles);

        setState(() {
          _isParsing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported ${files.length} files successfully!')),
          );
          Navigator.of(context).pop();
        }
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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paste the complete PTZ text below. The system will parse it and create the file structure on your canvas.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ptzController,
                decoration: const InputDecoration(
                  labelText: 'PTZ Content *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 20,
                minLines: 10,
                keyboardType: TextInputType.multiline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'PTZ content cannot be empty';
                  }
                  if (_validationError != null) {
                    return _validationError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_validationError != null) ...[
                Text(
                  'Error: $_validationError',
                  style: TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],
              if (_isParsing) const CircularProgressIndicator() else ElevatedButton(
                onPressed: _importPtz,
                child: const Text('Import and Create Files'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
