import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart;

class SyntaxHighlighter {
  // Маппинг расширений файлов к языкам подсветки
  static const Map<String, String> _languageMap = {
    'dart': 'dart',
    'yaml': 'yaml',
    'yml': 'yaml',
    'json': 'json',
    'html': 'html',
    'css': 'css',
    'xml': 'xml',
    'md': 'markdown',
    'txt': 'plaintext',
    'py': 'python',
  };

  /// Получение языка по расширению
  static String getLanguage(String filePath) {
    final extension = _extractExtension(filePath).toLowerCase();
    return _languageMap[extension] ?? 'plaintext';
  }

  /// Создание HighlightView для синтаксиса
  static Widget buildHighlightView({
    required String code,
    required String language,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    return HighlightView(
      code,
      language: language,
      theme: githubTheme,
      padding: padding,
      textStyle: const TextStyle(fontFamily: 'Courier', fontSize: 14),
    );
  }

  /// Извлечение расширения файла из пути
  static String _extractExtension(String path) {
    final parts = path.split('.');
    return parts.length > 1 ? parts.last : '';
  }
}
