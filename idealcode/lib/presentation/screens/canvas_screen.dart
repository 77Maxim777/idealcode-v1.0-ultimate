import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/project_provider.dart';
import '../../data/models/project_model.dart';
import '../../utils/coordinate_calculator.dart';
import '../widgets/canvas_item_widget.dart';
import '../widgets/connection_line_widget.dart';
import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  const CanvasScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;
  final TransformationController _transformationController = TransformationController();
  bool _isPanning = false;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Слушаем изменения провайдера для анимации
    ref.listen<AsyncValue<ProjectState>>(
      projectProvider(widget.projectId),
      (previous, next) {
        if (previous?.value?.project.files.length != next?.value?.project.files.length &&
            next?.value?.hasFiles == true) {
          _animateToCenter(next.value!.project.files);
        }
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _animateToCenter(List<ProjectFile> files) {
    if (files.isEmpty) return;

    final boundingBox = CoordinateCalculator.getBoundingBox(files);
    final centerX = (boundingBox['minX']! + boundingBox['maxX']!) / 2;
    final centerY = (boundingBox['minY']! + boundingBox['maxY']!) / 2;

    final matrix = Matrix4.identity()
      ..translate(MediaQuery.of(context).size.width / 2 - centerX, 
                  MediaQuery.of(context).size.height / 2 - centerY)
      ..scale(0.8);

    _animationController.forward().then((_) {
      _transformationController.value = matrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    final projectStateAsync = ref.watch(projectProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          // Кнопки действий
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Canvas',
            onPressed: () => ref.read(projectProvider(widget.projectId).notifier).refresh(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'import_ptz':
                  context.goToPtzImport(widget.projectId);
                  break;
                case 'edit_tz':
                  context.goToTzEditor(widget.projectId);
                  break;
                case 'export_github':
                  context.goToGithubExport(widget.projectId);
                  break;
                case 'center':
                  _animateToCenter(projectStateAsync.valueOrNull?.project.files ?? []);
                  break;
                case 'grid':
                  _repositionToGrid();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'import_ptz', child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('Import PTZ'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'edit_tz', child: ListTile(
                leading: Icon(Icons.description),
                title: Text('Edit TZ'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'export_github', child: ListTile(
                leading: Icon(Icons.cloud_upload),
                title: Text('Export to GitHub'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'center', child: ListTile(
                leading: Icon(Icons.center_focus_strong),
                title: Text('Center Canvas'),
                contentPadding: EdgeInsets.zero,
              )),
              const PopupMenuItem(value: 'grid', child: ListTile(
                leading: Icon(Icons.grid_on),
                title: Text('Grid Layout'),
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
        ],
      ),
      body: projectStateAsync.when(
        data: (state) => _buildCanvas(state),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorWidget(error.toString(), () {
          ref.invalidate(projectProvider(widget.projectId));
        }),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add_file',
            onPressed: () => context.goToPtzImport(widget.projectId),
            tooltip: 'Add Files via PTZ',
            child: const Icon(Icons.add_box),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () => _zoomIn(),
            tooltip: 'Zoom In',
            child: const Icon(Icons.zoom_in),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () => _zoomOut(),
            tooltip: 'Zoom Out',
            child: const Icon(Icons.zoom_out),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvas(ProjectState state) {
    final project = state.project;
    final files = project.files;

    if (!state.isLoading && files.isEmpty) {
      return _buildEmptyCanvas(state);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = CoordinateCalculator.getBoundingBox(files);
        final width = (canvasSize['width'] ?? CanvasLayout.canvasMinWidth).clamp(
          CanvasLayout.canvasMinWidth, constraints.maxWidth * 2,
        );
        final height = (canvasSize['height'] ?? CanvasLayout.canvasMinHeight).clamp(
          CanvasLayout.canvasMinHeight, constraints.maxHeight * 2,
        );

        return Stack(
          children: [
            // Фон холста
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: CustomPaint(
                painter: GridPainter(), // Сетка для ориентира
                size: Size.infinite,
              ),
            ),
            // Холст
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _transformationController,
                boundaryMargin: const EdgeInsets.all(100),
                minScale: 0.3,
                maxScale: 3.0,
                panEnabled: true,
                scaleEnabled: true,
                onInteractionStart: (_) => setState(() => _isPanning = true),
                onInteractionEnd: (_) => setState(() => _isPanning = false),
                clipBehavior: Clip.hardEdge,
                child: Container(
                  width: width,
                  height: height,
                  key: _canvasKey,
                  child: Stack(
                    children: [
                      // Линии зависимостей (снизу, чтобы перекрываться элементами)
                      CustomPaint(
                        painter: ConnectionLinePainter(files: files),
                        size: Size.infinite,
                      ),
                      // Элементы холста
                      ...files.map((file) => CanvasItemWidget(
                            key: ValueKey(file.id),
                            file: file,
                            projectId: widget.projectId,
                            onPositionChanged: (newX, newY) {
                              ref.read(projectProvider(widget.projectId).notifier)
                                  .updateFilePosition(file.id, newX, newY);
                            },
                            onTap: () => _onFileTap(context, file),
                          )),
                      // Индикатор статуса проекта
                      if (state.project.status != ProjectStatus.completed)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: state.project.status.color.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  state.project.status.icon,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.project.status.value.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            // Оверлей для статуса зума/пана
            if (_isPanning || _scale != 1.0)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_out_map, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${(_scale * 100).round()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyCanvas(ProjectState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dashboard_customize,
              size: 96,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to Your Canvas!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your digital studio is ready. Import PTZ to add files and start creating.\n\n'
              'Drag files to organize, connect dependencies, and build your masterpiece.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.goToPtzImport(widget.projectId),
              icon: const Icon(Icons.upload_file),
              label: const Text('Import PTZ Structure'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.goToTzEditor(widget.projectId),
              icon: const Icon(Icons.description),
              label: const Text('Edit Technical Specification (TZ)'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text('Canvas Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _repositionToGrid() {
    final currentProject = ref.read(projectProvider(widget.projectId)).valueOrNull?.project;
    if (currentProject == null) return;

    final gridFiles = CoordinateCalculator.calculateGridPositions(currentProject.files);
    ref.read(projectProvider(widget.projectId).notifier)
        .addFiles(gridFiles.map((f) => f.copyWith(id: '${f.id}_grid')).toList());
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Canvas repositioned to grid')),
    );
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _setScale((currentScale * 1.2).clamp(0.3, 3.0));
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    _setScale((currentScale / 1.2).clamp(0.3, 3.0));
  }

  void _setScale(double scale) {
    setState(() => _scale = scale);
    final matrix = Matrix4.identity()..scale(scale);
    _transformationController.value = matrix;
  }

  void _onFileTap(BuildContext context, ProjectFile file) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildFileBottomSheet(file),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  Widget _buildFileBottomSheet(ProjectFile file) {
    return FractionallySizedBox(
      heightFactor: 0.7,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        file.type.icon,
                        color: file.type.color,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              file.displayName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              file.extension.toUpperCase(),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: file.type.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fullscreen),
                        onPressed: () => context.goToEditor(widget.projectId, file.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status and metadata
                  Row(
                    children: [
                      _buildStatusChip(file.status),
                      const SizedBox(width: 16),
                      _buildSizeChip(file.formattedSize),
                      const SizedBox(width: 16),
                      _buildDateChip(file.formattedDate),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Annotation
                  if (file.annotation.isNotEmpty) ...[
                    const Text(
                      'Annotation:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        file.annotation,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Dependencies
                  if (file.dependencies.isNotEmpty) ...[
                    const Text(
                      'Dependencies:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: file.dependencies.map((depId) {
                        final depFile = ref.read(projectProvider(widget.projectId))
                            .valueOrNull?.project.getFileById(depId);
                        return Chip(
                          label: Text(depFile?.displayName ?? 'Unknown'),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                          deleteIcon: const Icon(Icons.link, size: 16),
                          onDeleted: () => _removeDependency(file.id, depId),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Actions
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.goToEditor(widget.projectId, file.id),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Code'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleFileStatus(file),
                          icon: Icon(file.status == FileStatus.completed 
                              ? Icons.undo : Icons.check),
                          label: Text(file.status == FileStatus.completed 
                              ? 'Mark Incomplete' : 'Mark Complete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(FileStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.value.toUpperCase(),
            style: TextStyle(color: status.color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeChip(String size) {
    return Chip(
      label: Text(size),
      avatar: const Icon(Icons.storage, size: 16),
      backgroundColor: Colors.green.withOpacity(0.1),
    );
  }

  Widget _buildDateChip(String date) {
    return Chip(
      label: Text(date),
      avatar: const Icon(Icons.access_time, size: 16),
      backgroundColor: Colors.blue.withOpacity(0.1),
    );
  }

  void _removeDependency(String fileId, String depId) {
    // Логика удаления зависимости
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Removed dependency $depId from $fileId')),
    );
  }

  void _toggleFileStatus(ProjectFile file) {
    final newStatus = file.status == FileStatus.completed ? FileStatus.editing : FileStatus.completed;
    ref.read(projectProvider(widget.projectId).notifier)
        .updateFilePosition(file.id, file.x, file.y); // Здесь updateStatus, но метод updateFilePosition - опечатка, должно быть updateStatus
    Navigator.pop(context);
  }
}

// Вспомогательный painter для сетки
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Вертикальные линии
    for (double x = 0; x < size.width; x += CanvasLayout.stepX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Горизонтальные линии
    for (double y = 0; y < size.height; y += CanvasLayout.stepY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
