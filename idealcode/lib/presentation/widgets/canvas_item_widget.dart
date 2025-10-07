import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/project_file_model.dart';
import '../../providers/project_provider.dart';
import '../../core/constants/app_constants.dart';
import '../file_type_icon.dart';

typedef PositionCallback = void Function(double newX, double newY);
typedef TapCallback = void Function();

class CanvasItemWidget extends ConsumerStatefulWidget {
  const CanvasItemWidget({
    super.key,
    required this.file,
    required this.projectId,
    this.onPositionChanged,
    this.onTap,
  });

  final ProjectFile file;
  final String projectId;
  final PositionCallback? onPositionChanged;
  final TapCallback? onTap;

  @override
  ConsumerState<CanvasItemWidget> createState() => _CanvasItemWidgetState();
}

class _CanvasItemWidgetState extends ConsumerState<CanvasItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _dragAnimation;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _dragAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.file.status.color;
    final typeColor = widget.file.type.color;

    return AnimatedBuilder(
      animation: _dragAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: _dragOffset + _dragAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Positioned(
              left: widget.file.x,
              top: widget.file.y,
              child: GestureDetector(
                onTapDown: (_) => _onTapStart(),
                onTap: widget.onTap,
                onPanStart: (_) => _onPanStart(),
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: Container(
                  width: AppConstants.canvasItemSize,
                  height: AppConstants.canvasItemHeight,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.2),
                        statusColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      if (_isDragging)
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Иконка типа
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: FileTypeIcon(
                            fileType: widget.file.type,
                            size: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Название файла
                        Flexible(
                          child: Text(
                            widget.file.displayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: typeColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Статус индикатор
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.file.status.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (_isDragging)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.drag_indicator,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTapStart() {
    _animationController.forward().then((_) => _animationController.reverse());
    _startHoverAnimation();
  }

  void _onPanStart() {
    setState(() {
      _isDragging = true;
    });
    _animationController.forward();
    _dragOffset = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    setState(() {
      _dragOffset += details.delta / _scaleAnimation.value;
    });

    // Обновляем позицию в реальном времени (debounced для производительности)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onPositionChanged != null) {
        final newX = widget.file.x + _dragOffset.dx;
        final newY = widget.file.y + _dragOffset.dy;
        widget.onPositionChanged!(newX, newY);
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    // Финальное обновление позиции
    if (widget.onPositionChanged != null) {
      final newX = widget.file.x + _dragOffset.dx;
      final newY = widget.file.y + _dragOffset.dy;
      widget.onPositionChanged!(newX, newY);
    }

    // Анимация возврата в позицию (elastic)
    _dragAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
      });
      _animationController.reverse();
    });
  }

  void _startHoverAnimation() {
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
}
