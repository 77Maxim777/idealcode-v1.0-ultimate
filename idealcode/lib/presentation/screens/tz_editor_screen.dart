import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';

class TzEditorScreen extends ConsumerStatefulWidget {
  const TzEditorScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<TzEditorScreen> createState() => _TzEditorScreenState();
}

class _TzEditorScreenState extends ConsumerState<TzEditorScreen> {
  late TextEditingController _controller;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    final projectState = ref.read(projectProvider(widget.projectId));
    _controller = TextEditingController(text: projectState.value!.project.description ?? '');
    _controller.addListener(() {
      setState(() {
        _hasUnsavedChanges = true;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveTz() async {
    await ref.read(projectProvider(widget.projectId).notifier).updateDescription(_controller.text);
    
    setState(() {
      _hasUnsavedChanges = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Technical Specification saved')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _controller.text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('TZ copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Technical Specification (TZ)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyToClipboard,
          ),
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveTz,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Characters: ${_controller.text.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (_hasUnsavedChanges)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Unsaved changes',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Describe your project\'s overall vision, goals, and key features here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveTz,
                icon: const Icon(Icons.save),
                label: const Text('Save TZ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
