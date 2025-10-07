import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../data/models/project_file_model.dart';
import '../utils/result.dart';
import 'dart:math' as math;

class ParseError {
  final String message;
  final int lineNumber;
  final String snippet;

  ParseError(this.message, {this.lineNumber = -1, this.snippet = ''});

  @override
  String toString() {
    if (lineNumber > 0) {
      return 'ParseError at line $lineNumber: $message\nSnippet: $snippet';
    }
    return 'ParseError: $message';
  }
}

/// Сервис для парсинга текста ПТЗ в список ProjectFile
class PtzParserService {
  // Регулярные выражения для парсинга ПТЗ
  static final RegExp _fileHeaderRegex = RegExp(
    r'^(\d+)\.\s*Файл:\s*(.+?)(?=\n|$)',
    multiLine: true,
    caseSensitive: false,
  );

  static final RegExp _annotationRegex = RegExp(
    r'Аннотация:\s*(.+?)(?=\nСвязи:|\n\d+\.|\n\n|$)',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  static final RegExp _dependenciesRegex = RegExp(
    r'Связи:\s*(.+?)(?=\n\d+\.|\n\n|$)',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  static final RegExp _fileNumberRegex = RegExp(r'файл(?:а)?\s*(\d+)');
  static final RegExp _pathRegex = RegExp(r'([a-zA-Z0-9_/.-]+\.[a-zA-Z0-9]+)');

  /// Основной метод парсинга ПТЗ текста
  static Result<List<ProjectFile>, ParseError> parsePTZ(String ptzText) {
    try {
      if (ptzText.trim().isEmpty) {
        return Result.error(ParseError('PTZ text is empty'));
      }

      // Нормализуем текст: удаляем лишние пробелы, добавляем переносы
      final normalizedText = _normalizeText(ptzText);

      final matches = _fileHeaderRegex.allMatches(normalizedText);

      if (matches.isEmpty) {
        return Result.error(ParseError(
          'No file definitions found. Expected format: "1. Файл: path/to/file.ext"'
        ));
      }

      final List<ProjectFile> files = [];
      final List<String> parsedLines = [];

      for (final match in matches) {
        final fileNumber = match.group(1)!;
        final rawPath = match.group(2)!.trim();

        // Очистка пути от лишнего
        final path = _cleanPath(rawPath);

        if (path.isEmpty) {
          return Result.error(ParseError(
            'Invalid file path in file #$fileNumber',
            lineNumber: _getLineNumber(ptzText, match.start),
          ));
        }

        // Извлекаем полный контекст для аннотации и связей
        final contextStart = match.start;
        final contextEnd = _findNextSectionEnd(normalizedText, contextStart);

        final contextText = normalizedText.substring(contextStart, contextEnd);
        parsedLines.add(contextText);

        // Парсинг аннотации
        final annotationMatch = _annotationRegex.firstMatch(contextText);
        final annotation = annotationMatch?.group(1)?.trim() ?? '';

        // Парсинг зависимостей
        final dependenciesMatch = _dependenciesRegex.firstMatch(contextText);
        final dependenciesText = dependenciesMatch?.group(1)?.trim() ?? '';

        // Парсинг этапов (опционально)
        final stageMatch = RegExp(r'📂\\s*ЭТАП\\s*\\d+:\\s*(.+?)(?=\\n📂|\\Z)').firstMatch(ptzText);
        final stage = stageMatch?.group(1)?.trim() ?? 'Unknown Stage';

        // Создание файла
        final fileId = '${fileNumber}_$path'.replaceAll('/', '_');
        final fileType = _getTypeFromPath(path);

        final projectFile = ProjectFile(
          id: fileId,
          path: path,
          annotation: annotation.isNotEmpty ? '$stage: $annotation' : stage,
          type: fileType,
          status: FileStatus.empty,
          dependencies: _parseDependencies(dependenciesText, files, fileNumber),
          lastModified: DateTime.now(),
        );

        files.add(projectFile);
      }

      // Проверка на циклические зависимости
      final cycleCheck = _detectCycles(files);
      if (cycleCheck.isNotEmpty) {
        return Result.error(ParseError('Circular dependencies detected: ${cycleCheck.join(', ')}'));
      }

      // Расчет позиций
      final positionedFiles = _calculateGridPositions(files);

      // Логируем парсинг для отладки
      debugPrint('Parsed ${files.length} files from PTZ');
      for (final line in parsedLines) {
        debugPrint('Parsed line: ${line.substring(0, math.min(100, line.length))}...');
      }

      return Result.success(positionedFiles);
    } catch (e, stackTrace) {
      debugPrint('PTZ parsing error: $e\n$stackTrace');
      return Result.error(ParseError('Parsing failed: ${e.toString()}'));
    }
  }

  /// Нормализация текста ПТЗ
  static String _normalizeText(String text) {
    return text
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// Очистка пути файла
  static String _cleanPath(String rawPath) {
    return rawPath
        .trim()
        .replaceAll(RegExp(r'["\'`]'), '')
        .replaceAll(RegExp(r'\\s+'), '_')
        .toLowerCase();
  }

  /// Парсинг зависимостей
  static List<String> _parseDependencies(
    String dependenciesText,
    List<ProjectFile> existingFiles,
    String currentFileNumber,
  ) {
    final dependencies = <String>[];

    if (dependenciesText.isEmpty) return dependencies;

    // Поиск номеров файлов
    final numberMatches = _fileNumberRegex.allMatches(dependenciesText);
    for (final match in numberMatches) {
      final depNumber = match.group(1);
      if (depNumber != null && depNumber != currentFileNumber) {
        final depFile = existingFiles.firstWhereOrNull(
          (file) => file.id.startsWith('${depNumber}_'),
        );
        if (depFile != null) {
          dependencies.add(depFile.id);
        }
      }
    }

    // Поиск путей
    final pathMatches = _pathRegex.allMatches(dependenciesText);
    for (final match in pathMatches) {
      final depPath = match.group(1)!;
      final depFile = existingFiles.firstWhereOrNull(
        (file) => file.path.toLowerCase().contains(depPath.toLowerCase()),
      );
      if (depFile != null && !dependencies.contains(depFile.id)) {
        dependencies.add(depFile.id);
      }
    }

    // Удаляем дубликаты и сортируем
    final result = dependencies.toSet().toList()..sort();

    // Проверка на само-зависимость
    final currentFile = existingFiles.isNotEmpty ? existingFiles.last : null;
    if (currentFile != null && result.contains(currentFile.id)) {
      result.remove(currentFile.id);
    }

    return result;
  }

  /// Поиск конца секции
  static int _findNextSectionEnd(String text, int start) {
    final remainingText = text.substring(start);
    final nextHeader = RegExp(r'\n\d+\.\s*Файл:').firstMatch(remainingText);
    if (nextHeader != null) {
      return start + nextHeader.start;
    }
    return text.length;
  }

  /// Получение номера строки для ошибки
  static int _getLineNumber(String text, int charIndex) {
    return text.substring(0, charIndex).split('\n').length;
  }

  /// Детекция циклических зависимостей
  static List<String> _detectCycles(List<ProjectFile> files) {
    final visited = <String>{};
    final recStack = <String>{};
    final cycles = <String>[];

    for (final file in files) {
      if (!visited.contains(file.id)) {
        final cycle = _detectCycleUtil(file, files, visited, recStack, []);
        if (cycle.isNotEmpty) {
          cycles.addAll(cycle);
        }
      }
    }

    return cycles.toSet().toList();
  }

  static List<String> _detectCycleUtil(
    ProjectFile file,
    List<ProjectFile> allFiles,
    Set<String> visited,
    Set<String> recStack,
    List<String> currentPath,
  ) {
    visited.add(file.id);
    recStack.add(file.id);
    currentPath.add(file.id);

    for (final depId in file.dependencies) {
      final depFile = allFiles.firstWhereOrNull((f) => f.id == depId);
      if (depFile == null) continue;

      if (!visited.contains(depFile.id)) {
        final cycle = _detectCycleUtil(depFile, allFiles, visited, recStack, currentPath);
        if (cycle.isNotEmpty) return cycle;
      } else if (recStack.contains(depFile.id)) {
        // Цикл найден
        final cycleStart = currentPath.indexOf(depFile.id);
        return currentPath.sublist(cycleStart);
      }
    }

    recStack.remove(file.id);
    currentPath.removeLast();
    return [];
  }

  /// Валидация ПТЗ текста перед парсингом
  static Result<String, ParseError> validatePTZ(String ptzText) {
    final normalized = _normalizeText(ptzText);

    if (normalized.length < 50) {
      return Result.error(ParseError('PTZ too short. Minimum expected length: 50 chars'));
    }

    final fileCount = _fileHeaderRegex.allMatches(normalized).length;
    if (fileCount < 1 || fileCount > 100) {
      return Result.error(ParseError('Invalid number of files: $fileCount. Expected 1-100'));
    }

    // Проверка на ключевые слова
    if (!normalized.toLowerCase().contains('файл') || 
        !normalized.toLowerCase().contains('аннотация')) {
      return Result.error(ParseError('PTZ missing required sections (Файл, Аннотация)'));
    }

    return Result.success(normalized);
  }

  /// Простой расчет позиций для сетки
  static List<ProjectFile> _calculateGridPositions(List<ProjectFile> files) {
    const double itemWidth = 120.0;
    const double itemHeight = 80.0;
    const double spacing = 20.0;
    const int itemsPerRow = 4;

    return files.map((file, index) {
      final row = index ~/ itemsPerRow;
      final col = index % itemsPerRow;
      final x = col * (itemWidth + spacing);
      final y = row * (itemHeight + spacing);
      
      return file.copyWith(x: x, y: y);
    }).toList();
  }

  /// Пример использования и тестирование
  static void testParser() {
    const testPtz = '''
📂 ЭТАП 1: КОНФИГУРАЦИОННЫЕ ФАЙЛЫ
1. Файл: pubspec.yaml
Аннотация: Основной файл конфигурации Flutter. Определяет зависимости и настройки.
Связи: Зависит от файла 2 (analysis_options.yaml).

2. Файл: analysis_options.yaml
Аннотация: Настройки линтера и анализатора кода.
Связи: Используется всем проектом.

📂 ЭТАП 2: МОДЕЛИ
3. Файл: lib/data/models/project_model.dart
Аннотация: Модель данных для проекта.
Связи: Зависит от файла 4, используется в экранах.
    ''';

    final result = parsePTZ(testPtz);
    result.fold(
      (error) => debugPrint('Test failed: $error'),
      (files) => debugPrint('Test success: ${files.length} files parsed'),
    );
  }
}

// Внешняя функция для определения типа файла по пути
FileType _getTypeFromPath(String path) {
  final parts = path.split('.');
  if (parts.length < 2) return FileType.resource;
  
  final extension = parts.last.toLowerCase();
  
  if (FileExtensions.configFiles.contains('.$extension')) return FileType.config;
  if (FileExtensions.codeFiles.contains('.$extension')) return FileType.code;
  if (FileExtensions.resourceFiles.contains('.$extension')) return FileType.resource;
  if (FileExtensions.docFiles.contains('.$extension')) return FileType.documentation;
  
  return FileType.resource;
}