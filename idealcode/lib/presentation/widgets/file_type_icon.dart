import 'package:flutter/material.dart';

import '../../data/models/project_file_model.dart';

/// Утилитарный виджет для отображения иконки в зависимости от типа файла
/// Использует Material Icons с цветовой схемой для каждого типа
/// Адаптируется под тему приложения
class FileTypeIcon extends StatelessWidget {
  const FileTypeIcon({
    super.key,
    required this.fileType,
    this.size = 24,
    this.color,
  });

  final FileType fileType;
  final double size;
  final Color? color;

  /// Цвет по умолчанию для каждого типа
  Color _getDefaultColor(BuildContext context) {
    switch (fileType) {
      case FileType.config:
        return Theme.of(context).colorScheme.primary;
      case FileType.code:
        return Colors.green;
      case FileType.resource:
        return Theme.of(context).colorScheme.secondary;
      case FileType.documentation:
        return Colors.purple;
    }
  }

  /// Иконка по типу файла
  IconData _getIconData() {
    switch (fileType) {
      case FileType.config:
        return Icons.settings;
      case FileType.code:
        return Icons.code;
      case FileType.resource:
        return Icons.folder_open;
      case FileType.documentation:
        return Icons.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? _getDefaultColor(context);

    return Icon(
      _getIconData(),
      color: iconColor,
      size: size,
      shadows: [
        Shadow(
          color: iconColor.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

/// Фабрика для создания иконки по пути файла
class FileTypeIconFactory {
  /// Создает иконку на основе расширения пути
  static Widget createFromPath(String path, {double size = 24, Color? color}) {
    final extension = path.split('.').last.toLowerCase();
    final fileType = _getFileTypeFromExtension(extension);

    return FileTypeIcon(
      fileType: fileType,
      size: size,
      color: color,
    );
  }

  /// Определение типа по расширению (расширение метода из ProjectFile)
  static FileType _getFileTypeFromExtension(String extension) {
    if (extension == 'yaml' || extension == 'yml' || extension == 'json' ||
        extension == 'xml' || extension == 'gradle' || extension == 'properties') {
      return FileType.config;
    }
    if (extension == 'dart' || extension == 'kt' || extension == 'java' ||
        extension == 'js' || extension == 'ts' || extension == 'py') {
      return FileType.code;
    }
    if (extension == 'png' || extension == 'jpg' || extension == 'svg' ||
        extension == 'mp3' || extension == 'pdf' || extension.contains('asset')) {
      return FileType.resource;
    }
    if (extension == 'md' || extension == 'txt' || extension == 'doc' ||
        extension == 'html') {
      return FileType.documentation;
    }
    return FileType.code; // Фоллбек
  }
}
