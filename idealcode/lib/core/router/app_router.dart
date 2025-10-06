import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/project_list_screen.dart';
import '../../presentation/screens/project_create_screen.dart';
import '../../presentation/screens/canvas_screen.dart';
import '../../presentation/screens/code_editor_screen.dart';
import '../../presentation/screens/tz_editor_screen.dart';
import '../../presentation/screens/ptz_import_screen.dart';
import '../../presentation/screens/github_export_screen.dart';
import '../../presentation/screens/settings_screen.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../core/constants/app_constants.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    errorBuilder: (context, state) => _errorPage(context, state.error),
    routes: [
      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
        routes: [
          // Home screen
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const ProjectListScreen(),
          ),
          
          // Create project
          GoRoute(
            path: AppRoutes.createProject,
            builder: (context, state) => const ProjectCreateScreen(),
          ),
          
          // Project canvas
          GoRoute(
            path: AppRoutes.projectCanvas,
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CanvasScreen(projectId: id);
            },
            routes: [
              // Code editor
              GoRoute(
                path: 'editor/:fileId',
                name: 'editor',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  final fileId = state.pathParameters['fileId']!;
                  return CodeEditorScreen(
                    projectId: id,
                    fileId: fileId,
                  );
                },
              ),
              
              // TZ editor
              GoRoute(
                path: 'tz',
                name: 'tz',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return TzEditorScreen(projectId: id);
                },
              ),
              
              // PTZ import
              GoRoute(
                path: 'ptz-import',
                name: 'ptz-import',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return PtzImportScreen(projectId: id);
                },
              ),
              
              // GitHub export
              GoRoute(
                path: 'github-export',
                name: 'github-export',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return GithubExportScreen(projectId: id);
                },
              ),
            ],
          ),
          
          // Settings
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
  
  static Widget _errorPage(BuildContext context, Object error) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => router.go(AppRoutes.home),
                icon: const Icon(Icons.home),
                label: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Router extensions for easier navigation
extension AppRouterExtension on BuildContext {
  void goToHome() => go(AppRoutes.home);
  
  void goToCreateProject() => go(AppRoutes.createProject);
  
  void goToProject(String projectId) => 
      goNamed('project', pathParameters: {'id': projectId});
  
  void goToCanvas(String projectId) => 
      goNamed('canvas', pathParameters: {'id': projectId});
  
  void goToEditor(String projectId, String fileId) => 
      goNamed('editor', pathParameters: {'id': projectId, 'fileId': fileId});
  
  void goToTzEditor(String projectId) => 
      goNamed('tz', pathParameters: {'id': projectId});
  
  void goToPtzImport(String projectId) => 
      goNamed('ptz-import', pathParameters: {'id': projectId});
  
  void goToGithubExport(String projectId) => 
      goNamed('github-export', pathParameters: {'id': projectId});
  
  void goToSettings() => go(AppRoutes.settings);
  
  void pop() => navigator.pop();
  
  bool get canPop => navigator.canPop();
}
