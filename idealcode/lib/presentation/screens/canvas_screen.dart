import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/project_provider.dart';
import '../widgets/canvas_item_widget.dart';
import '../widgets/connection_line_widget.dart';

class CanvasScreen extends ConsumerWidget {
  const CanvasScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectState = ref.watch(projectProvider(projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(projectState.when(
          data: (state) => state.project.title,
          loading: () => 'Loading...',
          error: (_, __) => 'Error',
        )),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'tz':
                  context.go('/project/$projectId/tz');
                  break;
                case 'import_ptz':
                  context.go('/project/$projectId/import-ptz');
                  break;
                case 'github_export':
                  context.go('/project/$projectId/github-export');
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'tz',
                  child: ListTile(
                    leading: Icon(Icons.description),
                    title: Text('Edit TZ'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'import_ptz',
                  child: ListTile(
                    leading: Icon(Icons.upload_file),
                    title: Text('Import PTZ'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'github_export',
                  child: ListTile(
                    leading: Icon(Icons.cloud_upload),
                    title: Text('Export to GitHub'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(projectProvider(projectId));
        },
        child: projectState.when(
          data: (state) {
            if (state.project.files.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.dashboard_customize,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No files in this project yet.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.go('/project/$projectId/import-ptz');
                      },
                      child: const Text('Import PTZ'),
                    ),
                  ],
                ),
              );
            }

            return InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(100),
              minScale: 0.5,
              maxScale: 2.0,
              child: SizedBox(
                width: 2000,
                height: 2000,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: const Size.infinite,
                      painter: ConnectionLinePainter(files: state.project.files),
                    ),
                    ...state.project.files.map((file) {
                      return CanvasItemWidget(
                        key: ValueKey(file.id),
                        file: file,
                        projectId: projectId,
                      );
                    }),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text('Error loading project: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(projectProvider(projectId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
