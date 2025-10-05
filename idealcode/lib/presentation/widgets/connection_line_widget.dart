import 'package:flutter/material.dart';

import '../../data/models/project_file_model.dart';

class ConnectionLinePainter extends CustomPainter {
  final List<ProjectFile> files;

  ConnectionLinePainter({required this.files});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.5)
      ..strokeWidth = 2.0;

    for (final file in files) {
      for (final dependencyId in file.dependencies) {
        // Find the dependency file
        final dependencyFile = files.firstWhere(
          (f) => f.id == dependencyId,
          orElse: () => files.first, // Fallback to first file if not found
        );

        final startPoint = Offset(file.x + 60, file.y + 40);
        final endPoint = Offset(dependencyFile.x + 60, dependencyFile.y + 40);

        // Draw a curved line for better visualization
        final controlPoint = Offset(
          (startPoint.dx + endPoint.dx) / 2,
          (startPoint.dy + endPoint.dy) / 2 - 30,
        );

        final path = Path();
        path.moveTo(startPoint.dx, startPoint.dy);
        path.quadraticBezierTo(
          controlPoint.dx,
          controlPoint.dy,
          endPoint.dx,
          endPoint.dy,
        );

        canvas.drawPath(path, paint);

        // Draw arrow at the end
        _drawArrow(canvas, endPoint, startPoint);
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset to, Offset from) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final direction = (to - from).direction;
    final arrowSize = 8.0;
    final arrowAngle = 0.5;

    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * cos(direction - arrowAngle),
      to.dy - arrowSize * sin(direction - arrowAngle),
    );
    path.lineTo(
      to.dx - arrowSize * cos(direction + arrowAngle),
      to.dy - arrowSize * sin(direction + arrowAngle),
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ConnectionLinePainter oldDelegate) {
    return oldDelegate.files != files;
  }
}
