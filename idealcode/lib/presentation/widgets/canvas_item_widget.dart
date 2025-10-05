import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/project_file_model.dart';
import '../widgets/file_type_icon.dart';

class CanvasItemWidget extends ConsumerStatefulWidget {
  const CanvasItemWidget({
    super.key,
    required this.file,
    required this.projectId,
  });

  final ProjectFile file;
  final String projectId;

  @override
  ConsumerState<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends ConsumerState<CanvasItemWidget> {
  @override
  Widget build(BuildContext context) {
    final projectNotifier = ref.read(projectProvider(widget.projectId).notifier);

    return Positioned(
      left: widget.file.x,
      top: widget.file.y,
      child: GestureDetector(
        onTap: () {
          context.go('/project/${widget.projectId}/editor/${widget.file.id}');
        },
        onPanUpdate: (details) {
          final newX = widget.file.x + details.delta.dx;
          final newY = widget.file.y + details.delta.dy;
          projectNotifier.updateFilePosition(widget.file.id, newX, newY);
        },
        onPanEnd: (details) {
          // Save the final position
          projectNotifier.updateFilePosition(widget.file.x, widget.file.y);
        },
        child: Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FileTypeIcon(fileType: widget.file.type),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  widget.file.name,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.file.status) {
      case FileStatus.empty:
        return Colors.grey.shade300;
      case FileStatus.editing:
        return Colors.white;
      case FileStatus.completed:
        return Colors.green.shade200;
      case FileStatus.error:
        return Colors.red.shade200;
    }
  }
}
