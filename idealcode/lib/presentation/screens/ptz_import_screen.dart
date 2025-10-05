import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';
import '../../services/ptz_parser_service.dart';
import '../../utils/coordinate_calculator.dart';

class PtzImportScreen extends ConsumerWidget {
  const PtzImportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import PTZ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Paste the complete PTZ text below. The system will parse it and create the file structure on your canvas.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Make sure your PTZ follows the format specified in the documentation.',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'PTZ Content',
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _importPtz(context, ref, controller.text),
                child: const Text('Import and Create Files'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _importPtz(BuildContext context, WidgetRef ref, String ptzText) {
    if (ptzText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PTZ content cannot be empty')),
      );
      return;
    }

    final result = PtzParserService.parsePTZ(ptzText);

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error parsing PTZ: $error')),
        );
      },
      (files) {
        final positionedFiles = CoordinateCalculator.calculateGridPositions(files);
        ref.read(projectProvider(projectId).notifier).addFiles(positionedFiles);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported ${files.length} files.')),
        );
        Navigator.of(context).pop();
      },
    );
  }
}
