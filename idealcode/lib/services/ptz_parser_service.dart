import 'package:collection/collection.dart';

import '../data/models/project_file_model.dart';
import '../utils/result.dart';

class PtzParserService {
  static final _fileRegex = RegExp(r'^\d+\.\s*Файл:\s*(.+)$', multiLine: true);
 static final _annotationRegex = RegExp(r' Аннотация :\s*(.+?)(?=\n Связи :|\n\d+\.|\Z)', multiLine: true, dotAll: true);
static final _dependenciesRegex = RegExp(r' Связи :\s*(.+?)(?=\n\d+\.|\Z)', multiLine: true, dotAll: true);

  static Result<List<ProjectFile>, String> parsePTZ(String ptzText) {
    try {
      final fileMatches = _fileRegex.allMatches(ptzText).toList();
      if (fileMatches.isEmpty) {
        return const Result.error('No file definitions found in PTZ.');
      }

      final List<ProjectFile> files = [];
      for (final match in fileMatches) {
        final path = match.group(1)!;
        final annotationMatch = _annotationRegex.firstMatch(ptzText.substring(match.start));
        final annotation = annotationMatch?.group(1) ?? '';
        
        final dependenciesMatch = _dependenciesRegex.firstMatch(ptzText.substring(match.start));
        final dependenciesText = dependenciesMatch?.group(1) ?? '';
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
    // Improved dependency parsing
    final List<String> dependencies = [];
    
    // Try to find file numbers in the text
    final numberMatches = RegExp(r'(\d+)').allMatches(text);
    for (final match in numberMatches) {
      final fileNumber = int.tryParse(match.group(1)!);
      if (fileNumber != null && fileNumber > 0 && fileNumber <= existingFiles.length) {
        // File numbers are 1-based in PTZ, but 0-based in our list
        final index = fileNumber - 1;
        if (index < existingFiles.length) {
          dependencies.add(existingFiles[index].id);
        }
      }
    }
    
    // Also try to find file paths directly
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
    if (path.endsWith('.yaml') || path.endsWith('.yml') || path.endsWith('.json')) return FileType.config;
    if (path.endsWith('.dart') || path.endsWith('.kt') || path.endsWith('.java') || path.endsWith('.xml')) return FileType.code;
    if (path.endsWith('.md') || path.endsWith('.txt')) return FileType.documentation;
    return FileType.resource;
  }
}
