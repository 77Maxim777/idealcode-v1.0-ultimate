import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../services/github_service.dart';
import '../../data/models/project_model.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

class GithubExportScreen extends ConsumerStatefulWidget {
  const GithubExportScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<GithubExportScreen> createState() => _GithubExportScreenState();
}

class _GithubExportScreenState extends ConsumerState<GithubExportScreen>
    with TickerProviderStateMixin {
  final _repoNameController = TextEditingController();
  late TextEditingController _tokenController;
  final _formKey = GlobalKey<FormState>();
  bool _isExporting = false;
  bool _hasToken = false;
  bool _showTokenInput = false;
  late AnimationController _progressController;
  String? _validationError;
  String? _repoUrl;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Загружаем проект и инициализируем
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });

    _repoNameController.addListener(_validateRepoName);
  }

  @override
  void dispose() {
    _repoNameController.dispose();
    _tokenController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final projectState = ref.read(projectProvider(widget.projectId));
    if (projectState is AsyncData<ProjectState> && projectState.value.project.title.isNotEmpty) {
      _repoNameController.text = projectState.value.project.title
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '-')
          .replaceAll(RegExp(r'-+'), '-')
          .trim();
      _validateRepoName();
    }

    // Проверяем токен
    final tokenResult = await GitHubService.getToken();
    tokenResult.fold(
      (error) => setState(() => _hasToken = false),
      (token) => setState(() {
        _hasToken = token != null && token.isNotEmpty;
        _showTokenInput = !_hasToken;
      }),
    );
  }

  void _validateRepoName() {
    final name = _repoNameController.text.trim();
    setState(() {
      _validationError = name.isEmpty
          ? 'Repository name is required'
          : (name.length < 3 || !RegExp(r'^[a-z0-9-]+$').hasMatch(name))
              ? 'Name must be 3-100 chars, lowercase letters, numbers, hyphens only'
              : null;
    });
  }

  Future<void> _configureToken() async {
    final validation = await GitHubService.validateToken(_tokenController.text);
    if (!validation.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validation.errorOrNull ?? 'Invalid token')),
      );
      return;
    }

    final saveResult = await GitHubService.saveToken(_tokenController.text);
    saveResult.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save token: $error')),
      ),
      (_) {
        setState(() {
          _hasToken = true;
          _showTokenInput = false;
          _tokenController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Token saved successfully')),
        );
      },
    );
  }

  Future<void> _startExport() async {
    if (_formKey.currentState!.validate() && _hasToken && !_isExporting) {
      final projectState = ref.read(projectProvider(widget.projectId));
      if (projectState is AsyncData<ProjectState>) {
        setState(() => _isExporting = true);

        final repoName = _repoNameController.text.trim();
        final project = projectState.value.project.copyWith(title: repoName);

        final result = await GitHubService.createRepositoryAndCommit(project);

        setState(() => _isExporting = false);

        result.fold(
          (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Export failed: $error')),
          ),
          (url) {
            setState(() => _repoUrl = url);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Project exported to GitHub!'),
                action: SnackBarAction(
                  label: 'View Repo',
                  onPressed: () {
                    // launchUrl(Uri.parse(url));
                  },
                ),
              ),
            );

            if (mounted) {
              _showSuccessDialog(url);
            }
          },
        );
      }
    }
  }

  void _showSuccessDialog(String url) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your project has been uploaded to GitHub.'),
            const SizedBox(height: 12),
            Text('Repository: $url'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // launchUrl(Uri.parse(url));
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in GitHub'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.goToHome();
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export to GitHub'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_repoUrl != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              onPressed: () {
                // launchUrl(Uri.parse(_repoUrl!));
              },
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
              // Интро
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Share your masterpiece with the world!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Export your project canvas to GitHub. Get a repo with all files, structure, and README.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Имя репозитория
              TextFormField(
                controller: _repoNameController,
                decoration: InputDecoration(
                  labelText: 'Repository Name *',
                  prefixIcon: const Icon(Icons.folder),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showRepoNamingHelp(),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Repository name is required';
                  }
                  if (value.trim().length < 3 || !RegExp(r'^[a-z0-9-]+$').hasMatch(value.trim())) {
                    return 'Invalid format: lowercase, 3-100 chars, hyphens only';
                  }
                  return null;
                },
              ),
              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
              const SizedBox(height: 24),

              // Секция токена
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _hasToken ? Icons.check_circle : Icons.warning,
                            color: _hasToken ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'GitHub Account Connection ${_hasToken ? '(Connected)' : '(Not Connected)'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _hasToken ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!_hasToken) ...[
                        const Text(
                          'Generate a Personal Access Token with "repo" permissions:\n'
                          '1. Go to github.com/settings/tokens\n'
                          '2. Generate new token (classic)\n'
                          '3. Select "repo" scope\n'
                          '4. Copy the token and paste below',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tokenController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'GitHub Token *',
                            prefixIcon: const Icon(Icons.key),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.visibility),
                              onPressed: () => setState(() => _tokenController.obscureText = false),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.startsWith('ghp_')) {
                              return 'Valid GitHub token is required (starts with ghp_)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _configureToken,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Token'),
                          ),
                        ),
                      ] else ...[
                        const Text('Your GitHub account is connected. You can change token anytime.'),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasToken = false;
                              _showTokenInput = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Change Account'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Кнопка экспорта
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_isExporting || _validationError != null || !_hasToken) 
                      ? null 
                      : _startExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isExporting ? 'Exporting...' : 'Export to GitHub'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              // Информация о проекте
              if (!_isExporting)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline),
                              const SizedBox(width: 12),
                              const Text('What will be exported:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text('- All files from canvas with content'),
                          const Text('- File structure and dependencies (README)'),
                          const Text('- .gitignore and basic setup'),
                          const SizedBox(height: 8),
                          Text('Files: ${ref.read(projectProvider(widget.projectId)).valueOrNull?.project.files.length ?? 0}'),
                          Text('Content size: ~${ref.read(projectProvider(widget.projectId)).valueOrNull?.project.files.fold(0, (sum, f) => sum + f.size) ?? 0} chars'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRepoNamingHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repository Naming'),
        content: const Text(
          'GitHub repo names:\n'
          '- 3-100 characters\n'
          '- Lowercase letters, numbers, hyphens only\n'
          '- No spaces or special chars\n'
          '- Auto-suggest: project-name-123456\n\n'
          'Example: my-flutter-app-2024',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
