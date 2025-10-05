import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';
import '../../services/github_service.dart';

class GithubExportScreen extends ConsumerStatefulWidget {
  const GithubExportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<GithubExportScreen> createState() => _GithubExportScreenState();
}

class _GithubExportScreenState extends ConsumerState<GithubExportScreen> {
  final _repoNameController = TextEditingController();
  final _tokenController = TextEditingController();
  bool _isExporting = false;
  bool _showTokenInput = false;

  @override
  void initState() {
    super.initState();
    final project = ref.read(projectProvider(widget.projectId)).value!.project;
    _repoNameController.text = project.title.replaceAll(' ', '-').toLowerCase();
    
    // Check if token already exists
    _checkExistingToken();
  }

  @override
  void dispose() {
    _repoNameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingToken() async {
    final tokenResult = await GitHubService.getToken();
    tokenResult.fold(
      (error) => null,
      (token) {
        if (token != null && token.isNotEmpty) {
          setState(() {
            _showTokenInput = false;
          });
        } else {
          setState(() {
            _showTokenInput = true;
          });
        }
      },
    );
  }

  Future<void> _saveToken() async {
    if (_tokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token cannot be empty')),
      );
      return;
    }

    final result = await GitHubService.saveToken(_tokenController.text);
    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save token: $error')),
        );
      },
      (_) {
        setState(() {
          _showTokenInput = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token saved successfully')),
        );
      },
    );
  }

  Future<void> _startExport() async {
    if (_repoNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repository name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isExporting = true;
    });

    final project = ref.read(projectProvider(widget.projectId)).value!.project;
    final projectToExport = project.copyWith(title: _repoNameController.text);

    final result = await GitHubService.createRepositoryAndCommit(projectToExport);

    if (mounted) {
      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $error')),
          );
        },
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Project "${projectToExport.title}" exported to GitHub!')),
          );
          Navigator.of(context).pop();
        },
      );
    }

    setState(() {
      _isExporting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export to GitHub'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure your GitHub repository',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _repoNameController,
              decoration: const InputDecoration(
                labelText: 'Repository Name',
                border: OutlineInputBorder(),
                helperText: 'GitHub repository names must be unique.',
              ),
            ),
            const SizedBox(height: 24),
            if (_showTokenInput) ...[
              const Text(
                'GitHub Personal Access Token',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Access Token',
                  border: OutlineInputBorder(),
                  helperText: 'Create a token with repo permissions at github.com/settings/tokens',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveToken,
                  child: const Text('Save Token'),
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    const Text('GitHub token configured'),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _showTokenInput = true;
                        });
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 24),
            if (_isExporting)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startExport,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Export Project'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
