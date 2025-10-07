import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/project_provider.dart';
import '../../data/models/project_file_model.dart';
import '../../utils/coordinate_calculator.dart';
import '../widgets/canvas_item_widget.dart';
import '../widgets/connection_line_widget.dart';
import '../../core/constants/app_constants.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _canvasKey = GlobalKey();
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final projectStateAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(projectProvider(widget.projectId).notifier).refresh(),
          ),
        ],
      ),
      body: projectStateAsync.when(
        data: (state) {
          final project = state.project;
          if (project.files.isEmpty) {
            return _buildEmptyCanvas();
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  InteractiveViewer(
                    transformationController: _transformationController,
                    onInteractionEnd: (details) {
                      if (details.velocity.pixelsPerSecond.distance > 0) {
                        setState(() {
                          _scale = 1.0;
                        });
                      }
                    },
                    child: Container(
                      key: _canvasKey,
                      width: double.infinity,
                      height: double.infinity,
                      child: CustomPaint(
                        painter: ConnectionLinePainter(
                          files: project.files,
                          // Убрали параметр scale, так как его нет в конструкторе
                        ),
                        child: Stack(
                          children: project.files.map((file) {
                            return CanvasItemWidget(
                              file: file,
                              projectId: widget.projectId,
                              onPositionChanged: (newX, newY) {
                                ref.read(projectProvider(widget.projectId).notifier)
                                  .updateFilePosition(file.id, newX, newY);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  _buildScaleIndicator(),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text('Error loading canvas: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(projectProvider(widget.projectId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyCanvas() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 96, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text('Welcome to Your Canvas!', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Your digital studio is ready. Start creating by importing PTZ to add files.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/ptz-import/${widget.projectId}'),
              child: const Text('Import PTZ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleIndicator() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Scale: ${_scale.toStringAsFixed(1)}x',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}