import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/project_list_provider.dart';
import '../../services/github_service.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final tokenResult = await GitHubService.getToken();
    tokenResult.fold(
      (error) => null,
      (token) {
        if (mounted) {
          setState(() {
            _hasToken = token != null && token.isNotEmpty;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            title: const Text('About IdealCode'),
            subtitle: const Text('Version 1.0.0'),
            leading: const Icon(Icons.info),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'IdealCode',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.code),
                children: [
                  const Text(
                      'IdealCode is a mobile creative studio for AI-powered development.'),
                ],
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('GitHub Integration'),
            subtitle: Text(_hasToken ? 'Connected' : 'Not connected'),
            leading: Icon(
              _hasToken ? Icons.link : Icons.link_off,
              color: _hasToken ? Colors.green : Colors.grey,
            ),
            trailing: TextButton(
              onPressed: () async {
                await GitHubService.authenticate();
                _checkToken();
              },
              child: const Text('Configure'),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all projects and data'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Data'),
                  content: const Text(
                      'This will permanently delete all projects and data. This action cannot be undone.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(projectListProvider.notifier).deleteAllProjects();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('All data cleared')),
                        );
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('GitHub Repository'),
            subtitle: const Text('View source code on GitHub'),
            leading: const Icon(Icons.code),
            onTap: () {
              launchUrl(Uri.parse(AppConstants.githubRepoUrl));
            },
          ),
        ],
      ),
    );
  }
}
