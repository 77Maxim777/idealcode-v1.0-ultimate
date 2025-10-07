import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/project_list_provider.dart';
import '../../services/github_service.dart';
import '../../services/storage_service.dart';
import '../../core/constants/app_constants.dart';
import '../../utils/result.dart';
import '../widgets/app_drawer.dart';
import '../../core/router/app_router.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasToken = false;
  String _appVersion = '1.0.0';
  int _projectCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    // Версия приложения
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = packageInfo.version;
    });

    // Количество проектов
    final projectsResult = await StorageService.getProjects();
    projectsResult.fold(
      (error) => _projectCount = 0,
      (projects) => setState(() => _projectCount = projects.length),
    );

    // GitHub токен
    final tokenResult = await GitHubService.getToken();
    tokenResult.fold(
      (error) => setState(() => _hasToken = false),
      (token) => setState(() => _hasToken = token != null && token.isNotEmpty),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          // Верхний баннер
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.palette,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'IdealCode Studio',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'v$_appVersion',
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_projectCount projects created',
                  style: TextStyle(color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Секция "Account & Integration"
          _buildSectionHeader('Account & Integration'),
          _buildGitHubCard(),
          const SizedBox(height: 16),

          // Секция "Data Management"
          _buildSectionHeader('Data Management'),
          _buildDataCard(),
          const SizedBox(height: 16),

          // Секция "About & Help"
          _buildSectionHeader('About'),
          _buildAboutCard(),
          const SizedBox(height: 16),

          // Секция "Licensing"
          _buildSectionHeader('Licensing'),
          _buildLicenseCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildGitHubCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        leading: Icon(
          _hasToken ? Icons.link : Icons.link_off,
          color: _hasToken ? Colors.green : Colors.red,
        ),
        title: const Text('GitHub Integration'),
        subtitle: Text(_hasToken ? 'Connected' : 'Not connected'),
        trailing: _hasToken
            ? TextButton(
                onPressed: _logoutGitHub,
                child: const Text('Disconnect', style: TextStyle(color: Colors.red)),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_hasToken) ...[
                  const Text('Connect your GitHub account to export projects.'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _connectGitHub,
                    icon: const Icon(Icons.link),
                    label: const Text('Connect GitHub'),
                  ),
                ] else ...[
                  const Text('Your GitHub account is connected. You can export projects anytime.'),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _changeToken,
                    icon: const Icon(Icons.edit),
                    label: const Text('Change Token'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.folder, color: Colors.blue),
            title: const Text('Local Storage'),
            subtitle: Text('$_projectCount projects stored locally'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showStorageInfo(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all projects and settings (irreversible)'),
            trailing: const Icon(Icons.warning, color: Colors.red),
            onTap: _clearAllData,
          ),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.orange),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export/Import projects (coming soon)'),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup feature coming in V2.0')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Philosophy'),
            subtitle: const Text('You\'re the artist, bots are your paints.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showPhilosophy,
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Tutorial'),
            subtitle: const Text('Learn how to use IdealCode'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _showHelp,
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Rate & Review'),
            subtitle: const Text('Support the project'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _rateApp,
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.copyright),
        title: const Text('License'),
        subtitle: const Text('MIT License\n\n© 2024 IdealCode Studio\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy...'),
        onTap: _showFullLicense,
      ),
    );
  }

  void _connectGitHub() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connect GitHub'),
        content: const Text(
          '1. Open GitHub Settings > Developer settings > Personal access tokens\n'
          '2. Generate new token (classic)\n'
          '3. Select scopes: repo (full control)\n'
          '4. Copy the token and paste in the dialog',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _changeToken();
            },
            child: const Text('Generate Token'),
          ),
        ],
      ),
    );
  }

  void _changeToken() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GitHub Token'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your Personal Access Token:'),
            const SizedBox(height: 12),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Token',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: (value) async {
                final result = await GitHubService.saveToken(value);
                result.fold(
                  (error) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $error')),
                  ),
                  (_) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Token updated!')),
                    );
                    setState(() => _hasToken = true);
                  },
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutGitHub() async {
    final result = await GitHubService.deleteToken();
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GitHub disconnected')),
        );
        setState(() => _hasToken = false);
      },
    );
  }

  void _clearAllData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete:\n'
          '• All projects ($_projectCount)\n'
          '• All local storage\n'
          '• GitHub token (if connected)\n\n'
          'This cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Удаляем данные
              await ref.read(projectListProvider.notifier).deleteAllProjects();
              await GitHubService.deleteToken();

              // Очистка кэша
              await StorageService.clearSettings();
              await SecureStorageService.clearAll();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All data cleared'),
                  backgroundColor: Colors.red,
                ),
              );

              setState(() {
                _projectCount = 0;
                _hasToken = false;
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear Everything'),
          ),
        ],
      ),
    );
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projects: $_projectCount'),
            Text('Storage: Local Hive database'),
            Text('Backup: Manual export (V2.0)'),
          ],
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

  void _showPhilosophy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Philosophy'),
        content: const Text(
          'You don\'t write code — you create conditions for its birth.\n\n'
          'You are the artist and conductor. Bots are your paints, embodying your vision.\n\n'
          '"Iron sharpens iron, and one person sharpens another\'s skills" — Proverbs 27:17\n\n'
          'IdealCode is your digital studio where code becomes art.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Beautiful!'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use IdealCode'),
        content: const SingleChildScrollView(
          child: Text(
            '1. Create Project: Set title and TZ vision\n'
            '2. Import PTZ: Paste detailed spec, auto-parse files\n'
            '3. Canvas: Drag files, connect dependencies visually\n'
            '4. Edit: Code editor with syntax highlighting\n'
            '5. Export: Push to GitHub, share your art\n\n'
            'Pro Tip: Start with TZ as your creative brief, PTZ as blueprint!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // Интеграция с store review (V2.0)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you! Rating coming in V2.0')),
    );
  }

  void _showFullLicense() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('MIT License'),
        content: const SingleChildScrollView(
          child: Text(
            'MIT License\n\n'
            'Copyright (c) 2024 IdealCode Studio\n\n'
            'Permission is hereby granted, free of charge, to any person obtaining a copy\n'
            'of this software and associated documentation files (the "Software"), to deal\n'
            'in the Software without restriction, including without limitation the rights\n'
            'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n'
            'copies of the Software, and to permit persons to whom the Software is\n'
            'furnished to do so, subject to the following conditions:\n\n'
            'The above copyright notice and this permission notice shall be included in all\n'
            'copies or substantial portions of the Software.\n\n'
            'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR\n'
            'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,\n'
            'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE\n'
            'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER\n'
            'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,\n'
            'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE\n'
            'SOFTWARE.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
