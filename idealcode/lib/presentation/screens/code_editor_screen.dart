import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';

import '../../providers/project_provider.dart';
import '../../services/syntax_highlighter.dart';

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
  late TextEditingController _controller;
  bool _hasUnsavedChanges = false;
  bool _showPreview = true;

  @override
  void initState() {
    super.initState();
    final projectState = ref.read(projectProvider(widget.projectId));
    final file = projectState.value!.project.files
        .firstWhere((file) => file.id == widget.fileId);
    _controller = TextEditingController(text: file.content);
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

  Future<void> _saveContent() async {
    await ref
        .read(projectProvider(widget.projectId).notifier)
        .updateFileContent(widget.fileId, _controller.text);
    
    setState(() {
      _hasUnsavedChanges = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider(widget.projectId));
    final file = projectState.value!.project.files
        .firstWhere((file) => file.id == widget.fileId);

    return Scaffold(
      appBar: AppBar(
        title: Text(file.name),
        actions: [
          IconButton(
            icon: Icon(_showPreview ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showPreview = !_showPreview;
              });
            },
          ),
          if (_hasUnsavedChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveContent,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: _showPreview ? 1 : 0,
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: _showPreview ? false : true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16.0),
              ),
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          if (_showPreview) ...[
            Container(
              height: 1,
              color: Colors.grey.shade300,
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Preview:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Text(
                        'Lines: ${_controller.text.split('\n').length}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: HighlightView(
                        _controller.text,
                        language: SyntaxHighlighter.getLanguage(file.path),
                        theme: githubTheme,
                        padding: const EdgeInsets.all(12),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _hasUnsavedChanges
          ? FloatingActionButton.extended(
              onPressed: _saveContent,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            )
          : null,
    );
  }
}
