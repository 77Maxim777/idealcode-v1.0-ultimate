import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/project_file_model.dart';
import '../../core/constants/app_constants.dart';

class ConnectionLinePainter extends CustomPainter {
  final List<ProjectFile> files;

  ConnectionLinePainter({
    required this.files,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Рисуем связи между файлами
    for (final file in files) {
      final startX = file.x + AppConstants.canvasItemSize / 2;
      final startY = file.y + AppConstants.canvasItemHeight / 2;

      for (final depId in file.dependencies) {
        final depFile = files.firstWhere(
          (f) => f.id == depId,
          orElse: () => files.firstWhere(
            (f) => f.path.contains(depId), 
            orElse: () => file, // fallback чтобы избежать ошибки
          ),
        );

        final endX = depFile.x + AppConstants.canvasItemSize / 2;
        final endY = depFile.y + AppConstants.canvasItemHeight / 2;

        // Рисуем линию
        canvas.drawLine(
          Offset(startX, startY),
          Offset(endX, endY),
          paint,
        );

        // Рисуем стрелку
        _drawArrow(canvas, Offset(startX, startY), Offset(endX, endY));
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset end) {
    final arrowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final direction = (end - start).normalized();
    const arrowSize = 8.0;
    const angle = 0.5; // Угол стрелки

    final arrowEnd1 = end - direction.rotated(angle) * arrowSize;
    final arrowEnd2 = end - direction.rotated(-angle) * arrowSize;

    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(arrowEnd1.dx, arrowEnd1.dy);
    path.lineTo(arrowEnd2.dx, arrowEnd2.dy);
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

// Extension для математических операций с Offset
extension OffsetUtils on Offset {
  Offset normalized() {
    final length = distance;
    if (length == 0) return this;
    return Offset(dx / length, dy / length);
  }

  Offset rotated(double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    return Offset(dx * cosA - dy * sinA, dx * sinA + dy * cosA);
  }
}