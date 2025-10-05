import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_constants.dart';
import 'presentation/screens/canvas_screen.dart';
import 'presentation/screens/code_editor_screen.dart';
import 'presentation/screens/github_export_screen.dart';
import 'presentation/screens/project_create_screen.dart';
import 'presentation/screens/project_list_screen.dart';
import 'presentation/screens/ptz_import_screen.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/tz_editor_screen.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  App({super.key});

  final _router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const ProjectListScreen(),
      ),
      GoRoute(
        path: AppRoutes.create,
        builder: (context, state) => const ProjectCreateScreen(),
      ),
      GoRoute(
        path: AppRoutes.project,
        builder: (context, state) {
          final projectId = state.pathParameters['id']!;
          return CanvasScreen(projectId: projectId);
        },
        routes: [
          GoRoute(
            path: AppRoutes.editor,
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              final fileId = state.pathParameters['fileId']!;
              return CodeEditorScreen(
                projectId: projectId,
                fileId: fileId,
              );
            },
          ),
          GoRoute(
            path: '/project/:id/tz',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              return TzEditorScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/project/:id/import-ptz',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              return PtzImportScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/project/:id/github-export',
            builder: (context, state) {
              final projectId = state.pathParameters['id']!;
              return GithubExportScreen(projectId: projectId);
            },
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IdealCode',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
