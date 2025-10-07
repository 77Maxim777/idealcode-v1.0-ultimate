import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

/// Боковое меню для навигации по приложению
/// Использует GoRouter для переходов между экранами
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).location;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            height: 240,
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConstants.primaryColor,
                  AppConstants.primaryColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.palette, size: 32, color: AppConstants.primaryColor),
                ),
                const SizedBox(height: 12),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppConstants.appVersion,
                  style: TextStyle(color: Colors.white.withOpacity(0.9)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mobile Creative Studio',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Home
                _buildDrawerItem(
                  context,
                  icon: Icons.home,
                  label: 'Home',
                  route: AppRoutes.home,
                  currentLocation: currentLocation,
                ),
                // Create Project
                _buildDrawerItem(
                  context,
                  icon: Icons.add_box,
                  label: 'Create Project',
                  route: AppRoutes.createProject,
                  currentLocation: currentLocation,
                ),
                // Settings
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  label: 'Settings',
                  route: AppRoutes.settings,
                  currentLocation: currentLocation,
                ),
                const Divider(height: 1),
                // Help & About
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  label: 'Help',
                  onTap: () => _showHelpDialog(context),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.palette,
                  label: 'Philosophy',
                  onTap: () => _showPhilosophyDialog(context),
                ),
                // Divider
                const Divider(height: 1),
                // Feedback
                _buildDrawerItem(
                  context,
                  icon: Icons.feedback,
                  label: 'Send Feedback',
                  onTap: _sendFeedback,
                ),
                // Version
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Version ${AppConstants.appVersion}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    String? route,
    VoidCallback? onTap,
    required String currentLocation,
  }) {
    final bool isSelected = route != null && currentLocation.startsWith(route);
    final Color? selectedColor = isSelected ? AppConstants.primaryColor : null;

    return ListTile(
      leading: Icon(
        icon,
        color: selectedColor,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selectedColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Colors.blue.withOpacity(0.1),
      onTap: onTap ?? () {
        context.go(route!);
        Navigator.pop(context);
      },
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
          'Quick Start:\n'
          '1. Create a new project\n'
          '2. Edit TZ (your vision)\n'
          '3. Import PTZ (file structure)\n'
          '4. Organize on canvas\n'
          '5. Export to GitHub\n\n'
          'Need more? Check the tutorial in settings.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.pop,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPhilosophyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Philosophy'),
        content: const Text(
          '"You don\'t write code — you create conditions for its birth. '
          'You are the artist and conductor. Bots are your paints, embodying your vision."\n\n'
          'IdealCode: Where code becomes art.',
        ),
        actions: [
          TextButton(
            onPressed: Navigator.pop,
            child: const Text('Inspiring!'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback() {
    // Интеграция email или form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback sent! (Coming in V2.0)'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
