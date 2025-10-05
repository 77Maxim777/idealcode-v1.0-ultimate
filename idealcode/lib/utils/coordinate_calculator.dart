import '../data/models/project_file_model.dart';

class CoordinateCalculator {
  static const double startX = 50.0;
  static const double startY = 50.0;
  static const double stepX = 150.0;
  static const double stepY = 120.0;
  static const int columns = 5;

  static List<ProjectFile> calculateGridPositions(List<ProjectFile> files) {
    return files.asMap().entries.map((entry) {
      final index = entry.key;
      final file = entry.value;
      final row = index ~/ columns;
      final col = index % columns;

      return file.copyWith(
        x: startX + col * stepX,
        y: startY + row * stepY,
      );
    }).toList();
  }
}
