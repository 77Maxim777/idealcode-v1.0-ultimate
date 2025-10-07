import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/project_file_model.dart';
import '../../core/constants/app_constants.dart';

/// CustomPainter для отрисовки линий зависимостей между элементами на холсте
/// Рисует изогнутые линии (Bezier) с стрелками, подсвечивает ошибки (циклические зависимости)
class ConnectionLinePainter extends CustomPainter {
  final List<ProjectFile> files;
  final Color lineColor;
  final double lineWidth;
  final bool showArrows;
  final double arrowSize;
  final Set<String> highlightedConnections; // Для подсветки активных связей

  ConnectionLinePainter({
    required this.files,
    this.lineColor = Colors.blue,
    this.lineWidth = AppConstants.connectionLineWidth,
    this.showArrows = true,
    this.arrowSize = 8.0,
    this.highlightedConnections = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    final normalPaint = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final highlightPaint = Paint()
      ..color = Colors.orange
      ..strokeWidth = lineWidth * 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final errorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = lineWidth * 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Группируем зависимости для оптимизации отрисовки
    final connectionMap = _buildConnectionMap(files);
    final sortedConnections = _sortConnectionsForRendering(connectionMap);

    // Рисуем все линии
    for (final connection in sortedConnections) {
      final fromFile = files.firstWhere((f) => f.id == connection.fromId);
      final toFile = files.firstWhere((f) => f.id == connection.toId);

      final isHighlighted = highlightedConnections.contains('${connection.fromId}-${connection.toId}');
      final isCircular = _isCircularDependency(fromFile, connection.toId, files);
      final paintToUse = isHighlighted 
          ? highlightPaint 
          : (isCircular ? errorPaint : normalPaint);

      _drawConnectionLine(canvas, fromFile, toFile, paintToUse, isCircular);
    }

    // Дополнительные слои: метки для циклических
    _drawCircularWarnings(canvas, files);
  }

  /// Построение карты зависимостей
  List<Connection> _buildConnectionMap(List<ProjectFile> files) {
    final connections = <Connection>[];

    for (final file in files) {
      for (final depId in file.dependencies) {
        if (depId != file.id && !_hasDuplicateDependency(file.dependencies, depId)) {
          connections.add(Connection(file.id, depId));
        }
      }
    }

    // Убираем дубликаты
    return connections.toSet().toList();
  }

  /// Сортировка для правильного наложения (задние линии рисуются первыми)
  List<Connection> _sortConnectionsForRendering(List<Connection> connections) {
    return connections
      ..sort((a, b) {
        final fromA = files.firstWhere((f) => f.id == a.fromId).y;
        final toA = files.firstWhere((f) => f.id == a.toId).y;
        final fromB = files.firstWhere((f) => f.id == b.fromId).y;
        final toB = files.firstWhere((f) => f.id == b.toId).y;

        final avgY_A = (fromA + toA) / 2;
        final avgY_B = (fromB + toB) / 2;

        return avgY_A.compareTo(avgY_B); // Снизу вверх для избежания перекрытий
      });
  }

  /// Рисование одной линии связи
  void _drawConnectionLine(
    Canvas canvas,
    ProjectFile fromFile,
    ProjectFile toFile,
    Paint paint,
    bool isCircular,
  ) {
    // Центры элементов
    final fromCenter = Offset(
      fromFile.x + AppConstants.canvasItemSize / 2,
      fromFile.y + AppConstants.canvasItemHeight / 2,
    );
    final toCenter = Offset(
      toFile.x + AppConstants.canvasItemSize / 2,
      toFile.y + AppConstants.canvasItemHeight / 2,
    );

    // Вычисление пути (Bezier для плавности)
    final path = Path();
    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromFile.dy;

    // Контрольные точки для кривой
    final control1 = Offset(
      fromCenter.dx + dx * 0.3,
      fromCenter.dy + dy * 0.2 + (dx > 0 ? 30 : -30), // Изгиб в сторону
    );
    final control2 = Offset(
      toCenter.dx - dx * 0.3,
      toCenter.dy - dy * 0.2 + (dx > 0 ? 30 : -30),
    );

    path.moveTo(fromCenter.dx, fromCenter.dy);
    path.cubicTo(
      control1.dx, control1.dy,
      control2.dx, control2.dy,
      toCenter.dx, toCenter.dy,
    );

    // Рисуем линию
    canvas.drawPath(path, paint);

    // Добавляем стрелку
    if (showArrows) {
      final endTangent = _getTangentAtEnd(path);
      _drawArrow(canvas, toCenter, endTangent.direction, isCircular);
    }

    // Если циклическая - рисуем красный крест
    if (isCircular) {
      _drawCircularIndicator(canvas, toCenter);
    }
  }

  /// Получение тангента в конце пути для стрелки
  Offset _getTangentAtEnd(Path path) {
    // Упрощенная оценка - направление от центров
    return Offset(1, 0); // Можно улучшить с помощью PathMetrics
  }

  /// Рисование стрелки
  void _drawArrow(Canvas canvas, Offset endPoint, double direction, bool isError) {
    final arrowPaint = Paint()
      ..color = isError ? Colors.red : lineColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final angle = 0.3; // Угол стрелки
    final path = Path();

    path.moveTo(endPoint.dx, endPoint.dy);
    path.lineTo(
      endPoint.dx - arrowSize * math.cos(direction - angle),
      endPoint.dy - arrowSize * math.sin(direction - angle),
    );
    path.lineTo(
      endPoint.dx - arrowSize * math.cos(direction + angle),
      endPoint.dy - arrowSize * math.sin(direction + angle),
    );
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  /// Рисование индикатора для циклической зависимости
  void _drawCircularIndicator(Canvas canvas, Offset center) {
    final warningPaint = Paint()
      ..color = Colors.red.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Простой треугольник предупреждения
    final path = Path();
    path.addPolygon([
      Offset(center.dx - 8, center.dy - 8),
      Offset(center.dx + 8, center.dy - 8),
      Offset(center.dx, center.dy + 8),
    ]);
    path.close();

    canvas.drawPath(path, warningPaint);
  }

  /// Рисование предупреждений для циклических зависимостей
  void _drawCircularWarnings(Canvas canvas, List<ProjectFile> files) {
    final cycles = _detectAllCycles(files);
    for (final cycle in cycles) {
      final cycleFiles = cycle.map((id) => files.firstWhere((f) => f.id == id)).toList();
      final center = Offset(
        cycleFiles.map((f) => f.x + AppConstants.canvasItemSize / 2).reduce(math.min + math.max) / 2,
        cycleFiles.map((f) => f.y + AppConstants.canvasItemHeight / 2).reduce(math.min + math.max) / 2,
      );

      // Текст предупреждения
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'CYCLE',
          style: TextStyle(
            color: Colors.red,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  /// Проверка на циклическую зависимость
  bool _isCircularDependency(ProjectFile startFile, String targetId, List<ProjectFile> allFiles) {
    final visited = <String>{};
    return _hasCycle(startFile.id, targetId, allFiles, visited);
  }

  bool _hasCycle(String currentId, String targetId, List<ProjectFile> allFiles, Set<String> visited) {
    if (currentId == targetId && visited.contains(currentId)) return true;

    final currentFile = allFiles.firstWhere((f) => f.id == currentId);
    visited.add(currentId);

    for (final depId in currentFile.dependencies) {
      if (depId == targetId || _hasCycle(depId, targetId, allFiles, visited)) {
        return true;
      }
    }

    visited.remove(currentId);
    return false;
  }

  /// Детекция всех циклов в графе
  List<List<String>> _detectAllCycles(List<ProjectFile> files) {
    final visited = <String>{};
    final recStack = <String>{};
    final cycles = <List<String>>[];

    for (final file in files) {
      if (!visited.contains(file.id)) {
        final cycle = _findCycle(file.id, files, visited, recStack);
        if (cycle.isNotEmpty) {
          cycles.add(cycle);
        }
      }
    }

    return cycles;
  }

  List<String> _findCycle(String nodeId, List<ProjectFile> files, Set<String> visited, Set<String> recStack) {
    visited.add(nodeId);
    recStack.add(nodeId);

    final nodeFile = files.firstWhere((f) => f.id == nodeId);
    for (final neighborId in nodeFile.dependencies) {
      if (!visited.contains(neighborId)) {
        final cycle = _findCycle(neighborId, files, visited, recStack);
        if (cycle.isNotEmpty) return cycle;
      } else if (recStack.contains(neighborId)) {
        // Цикл найден
        final startIndex = recStack.toList().indexOf(neighborId);
        return recStack.toList().sublist(startIndex)..add(nodeId);
      }
    }

    recStack.remove(nodeId);
    return [];
  }

  /// Проверка на дубликат зависимости
  bool _hasDuplicateDependency(List<String> dependencies, String depId) {
    return dependencies.where((d) => d == depId).length > 1;
  }

  /// Самосвязь (петля)
  void _drawSelfLoop(Canvas canvas, Offset center, Paint paint) {
    final path = Path();
    final radius = 20.0;
    final startAngle = math.pi / 2;
    final sweepAngle = 2 * math.pi * 0.7; // 70% круга

    path.addArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle);
    canvas.drawPath(path, paint);

    // Стрелка на петле
    final arrowPoint = center + Offset(radius * math.cos(startAngle + sweepAngle), 
                                      radius * math.sin(startAngle + sweepAngle));
    _drawArrow(canvas, arrowPoint, startAngle + sweepAngle, false);
  }

  @override
  bool shouldRepaint(covariant ConnectionLinePainter oldDelegate) {
    return oldDelegate.files != files ||
           oldDelegate.lineColor != lineColor ||
           oldDelegate.highlightedConnections != highlightedConnections;
  }
}

/// Модель связи
class Connection {
  final String fromId;
  final String toId;

  const Connection(this.fromId, this.toId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Connection && fromId == other.fromId && toId == other.toId;

  @override
  int get hashCode => fromId.hashCode ^ toId.hashCode;

  @override
  String toString() => 'Connection($fromId -> $toId)';
}

/// Подсветка конфликтов (неиспользуемые зависимости, orphaned)
void _highlightConflicts(Canvas canvas, List<ProjectFile> files) {
  // Логика для конфликтов: неиспользуемые зависимости и т.д.
  // Можно добавить красные пульсирующие линии для orphaned файлов
  
  final orphanedFiles = files.where((f) => f.dependencies.isEmpty && 
      files.any((other) => other.dependencies.contains(f.id))).toList();

  for (final file in orphanedFiles) {
    final center = Offset(
      file.x + AppConstants.canvasItemSize / 2,
      file.y + AppConstants.canvasItemHeight / 2,
    );

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 15, paint);
  }
}
