import 'package:collection/collection.dart';

import '../data/models/project_file_model.dart';
import '../utils/result.dart';

class PtzParserService {
  static final _fileRegex = RegExp(r'^\d+\.\s*File:\s*(.+)$', multiLine: true);
  // Исправленные регулярные выражения:
  static final _annotationRegex = RegExp(r'(?s)Annotation:\s*(.+?)(?=\nDependencies:|\n\d+\.|$)');
  static final _dependenciesRegex = RegExp(r'(?s)Dependencies:\s*(.+?)(?=\n\d+\.|$)');
  
  static Result<List<ProjectFile>, String> parsePTZ(String ptzText) {
    try {
      final fileMatches = _fileRegex.allMatches(ptzText).toList();
      if (fileMatches.isEmpty) {
        return const Result.error(
          'No file definitions found in PTZ. Make sure to use "File:" keyword.'
        );
      }

      final List<ProjectFile> files = [];
      for (final match in fileMatches) {
        final path = match.group(1)?.trim() ?? '';
        if (path.isEmpty) continue;
        
        // Ищем аннотацию и связи в тексте после текущей позиции
        final annotationMatch = _annotationRegex.firstMatch(ptzText.substring(match.end));
        final annotation = annotationMatch?.group(1)?.trim() ?? '';
        
        final dependenciesMatch = _dependenciesRegex.firstMatch(ptzText.substring(match.end));
        final dependenciesText = dependenciesMatch?.group(1)?.trim() ?? '';
        final dependencies = _parseDependencies(dependenciesText, files);

        final file = ProjectFile(
          id: path, 
          path: path,
          type: _getFileType(path),
          lastModified: DateTime.now(),
          dependencies: dependencies,
        );
        files.add(file);
      }
      return Result.success(files);
    } catch (e) {
      return Result.error('Failed to parse PTZ: $e');
    }
  }

  static List<String> _parseDependencies(String text, List<ProjectFile> existingFiles) {
    final List<String> dependencies = [];
    
    // Проверяем, что текст не пустой
    if (text.isEmpty) return dependencies;
    
    // Ищем номера файлов (1., 2., и т.д.)
    final numberMatches = RegExp(r'(\d+)\.').allMatches(text);
    for (final match in numberMatches) {
      final fileNumber = int.tryParse(match.group(1)!);
      if (fileNumber != null && fileNumber > 0 && fileNumber <= existingFiles.length) {
        dependencies.add(existingFiles[fileNumber - 1].id);
      }
    }
    
    // Ищем пути к файлам
    final pathMatches = RegExp(r'([a-zA-Z0-9_\-/]+\.[a-zA-Z0-9]+)').allMatches(text);
    for (final match in pathMatches) {
      final path = match.group(1)!;
      final file = existingFiles.firstWhereOrNull((f) => f.path.contains(path));
      if (file != null && !dependencies.contains(file.id)) {
        dependencies.add(file.id);
      }
    }
    
    return dependencies;
  }

  static FileType _getFileType(String path) {
    final ext = path.split('.').last.toLowerCase();
    
    if (ext == 'yaml' || ext == 'yml' || ext == 'json') return FileType.config;
    if (ext == 'dart' || ext == 'kt' || ext == 'java' || ext == 'xml') return FileType.code;
    if (ext == 'md' || ext == 'txt') return FileType.documentation;
    return FileType.resource;
  }
}
