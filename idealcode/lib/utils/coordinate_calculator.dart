import '../data/models/project_file_model.dart';
import '../core/constants/app_constants.dart';

/// Утилита для расчета позиций элементов на холсте
class CoordinateCalculator {
  /// Базовые константы сетки (из AppConstants)
  static const double _startX = CanvasLayout.startX;
  static const double _startY = CanvasLayout.startY;
  static const double _stepX = CanvasLayout.stepX;
  static const double _stepY = CanvasLayout.stepY;
  static const int _columns = CanvasLayout.columns;
  static const double _gridMargin = CanvasLayout.gridMargin;
  static const double _minDistanceBetweenItems = 20.0;

  /// Расчет позиций для сетки (равномерное распределение)
  static List<ProjectFile> calculateGridPositions(List<ProjectFile> files) {
    if (files.isEmpty) return [];

    final List<ProjectFile> positionedFiles = [];
    int index = 0;

    for (final file in files) {
      final row = index ~/ _columns;
      final col = index % _columns;

      final x = _startX + col * _stepX + _gridMargin;
      final y = _startY + row * _stepY + _gridMargin;

      final positionedFile = file.copyWith(
        x: x.clamp(0.0, double.infinity),
        y: y.clamp(0.0, double.infinity),
        lastModified: DateTime.now(), // Обновляем время
      );

      positionedFiles.add(positionedFile);
      index++;
    }

    return positionedFiles;
  }

  /// Расчет позиций по зависимостям (дерево или граф)
  /// Пытается минимизировать пересечения
  static List<ProjectFile> calculateDependencyPositions(List<ProjectFile> files) {
    if (files.isEmpty) return files;

    // Сначала размещаем корневые файлы (без зависимостей)
    final rootFiles = files.where((f) => f.dependencies.isEmpty).toList();
    final dependentFiles = files.where((f) => f.dependencies.isNotEmpty).toList();

    List<ProjectFile> positionedFiles = [];

    // Размещаем корневые в первой строке
    for (int i = 0; i < rootFiles.length; i++) {
      final x = _startX + i * (_stepX * 1.5);
      final y = _startY;
      positionedFiles.add(rootFiles[i].copyWith(x: x, y: y));
    }

    // Для зависимых - размещаем ниже родителей
    for (final depFile in dependentFiles) {
      double bestX = _startX;
      double bestY = _startY + _stepY * 2; // Вторая строка по умолчанию

      // Найти позицию рядом с основной зависимостью
      final primaryDep = positionedFiles.firstWhere(
        (f) => depFile.dependencies.contains(f.id),
        orElse: () => positionedFiles.first,
      );

      // Размещаем справа от родителя
      bestX = primaryDep.x + _stepX * 0.8;
      bestY = primaryDep.y + _stepY * 0.5;

      // Проверяем коллизии
      bestX = _avoidCollisions(positionedFiles, bestX, bestY, depFile);

      positionedFiles.add(depFile.copyWith(x: bestX, y: bestY));
    }

    return positionedFiles;
  }

  /// Расчет лучшей позиции, избегая коллизий
  static double _avoidCollisions(
    List<ProjectFile> existingFiles,
    double proposedX,
    double proposedY,
    ProjectFile newFile,
  ) {
    const double itemWidth = AppConstants.canvasItemSize;
    const double itemHeight = AppConstants.canvasItemHeight;
    const double margin = _minDistanceBetweenItems / 2;

    double x = proposedX.clamp(_startX, double.infinity);
    double y = proposedY.clamp(_startY, double.infinity);

    // Проверяем пересечения с существующими
    bool hasCollision = true;
    int attempts = 0;
    const maxAttempts = 10;

    while (hasCollision && attempts < maxAttempts) {
      hasCollision = false;

      for (final existing in existingFiles) {
        final dx = (x - existing.x).abs();
        final dy = (y - existing.y).abs();

        if (dx < itemWidth + margin && dy < itemHeight + margin) {
          // Коллизия: сдвигаем вправо и вниз
          x += _stepX * 0.3;
          y += _stepY * 0.3;
          hasCollision = true;
          break;
        }
      }

      attempts++;
      x = x.clamp(_startX, double.infinity);
      y = y.clamp(_startY, double.infinity);
    }

    // Снэп к сетке
    final col = ((x - _startX) / _stepX).round();
    final row = ((y - _startY) / _stepY).round();

    return {
      'x': _startX + col * _stepX + _gridMargin,
      'y': _startY + row * _stepY + _gridMargin,
    };
  }

  /// Центрирование всех элементов
  static List<ProjectFile> centerPositions(List<ProjectFile> files) {
    if (files.isEmpty) return files;

    // Найти bounding box
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final file in files) {
      minX = minX < file.x ? minX : file.x;
      maxX = maxX > file.x ? maxX : file.x;
      minY = minY < file.y ? minY : file.y;
      maxY = maxY > file.y ? maxY : file.y;
    }

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;
    final canvasCenterX = CanvasLayout.canvasMinWidth / 2;
    final canvasCenterY = CanvasLayout.canvasMinHeight / 2;

    final offsetX = canvasCenterX - centerX;
    final offsetY = canvasCenterY - centerY;

    return files.map((file) => file.copyWith(
      x: file.x + offsetX,
      y: file.y + offsetY,
    )).toList();
  }

  /// Масштабирование позиций под экран
  static List<ProjectFile> scalePositions(List<ProjectFile> files, double scaleFactor) {
    if (scaleFactor <= 0) return files;

    return files.map((file) => file.copyWith(
      x: file.x * scaleFactor,
      y: file.y * scaleFactor,
    )).toList();
  }

  /// Проверка на коллизию между двумя файлами
  static bool hasCollision(ProjectFile file1, ProjectFile file2) {
    const double itemWidth = AppConstants.canvasItemSize;
    const double itemHeight = AppConstants.canvasItemHeight;
    const double margin = _minDistanceBetweenItems / 2;

    final dx = (file1.x - file2.x).abs();
    final dy = (file1.y - file2.y).abs();

    return dx < itemWidth + margin && dy < itemHeight + margin;
  }

  /// Получить bounding box холста
  static Map<String, double> getBoundingBox(List<ProjectFile> files) {
    if (files.isEmpty) {
      return {
        'minX': _startX,
        'minY': _startY,
        'maxX': CanvasLayout.canvasMinWidth,
        'maxY': CanvasLayout.canvasMinHeight,
        'width': CanvasLayout.canvasMinWidth,
        'height': CanvasLayout.canvasMinHeight,
      };
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final file in files) {
      minX = minX < file.x ? minX : file.x;
      maxX = maxX > file.x ? maxX : file.x;
      minY = minY < file.y ? minY : file.y;
      maxY = maxY > file.y ? maxY : file.y;
    }

    final width = maxX - minX + AppConstants.canvasItemSize;
    final height = maxY - minY + AppConstants.canvasItemHeight;

    return {
      'minX': minX,
      'minY': minY,
      'maxX': maxX,
      'maxY': maxY,
      'width': width.clamp(CanvasLayout.canvasMinWidth, double.infinity),
      'height': height.clamp(CanvasLayout.canvasMinHeight, double.infinity),
    };
  }
}
