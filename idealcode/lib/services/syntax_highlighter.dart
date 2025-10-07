import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

/// Сервис для подсветки синтаксиса кода
/// Поддерживает маппинг расширений файлов к языкам подсветки (Dart, YAML, JSON + расширения для Flutter/мобильной разработки)
/// Позволяет создавать готовые HighlightView виджеты и тематизировать (light/dark)
class SyntaxHighlighter {
  /// Маппинг расширений файлов (lowercase) к языкам подсветки
  /// Поддержка ключевых языков для Flutter/Dart проектов + общие
  static const Map<String, String> _languageMap = {
    // Dart/Flutter
    'dart': 'dart',

    // Kotlin/Android
    'kt': 'kotlin',
    'kts': 'kotlin',
    'java': 'java',

    // XML (Android layouts, Gradle)
    'xml': 'xml',

    // YAML (pubspec, configs)
    'yaml': 'yaml',
    'yml': 'yaml',

    // JSON (configs, API responses)
    'json': 'json',
    'json5': 'json',

    // Markdown (docs)
    'md': 'markdown',
    'markdown': 'markdown',
    'mdx': 'markdown',

    // Gradle/Build
    'gradle': 'gradle',
    'properties': 'properties',

    // JS/TS (plugins, web)
    'js': 'javascript',
    'jsx': 'jsx',
    'ts': 'typescript',
    'tsx': 'tsx',

    // Python (scripts, AI integrations)
    'py': 'python',

    // C/C++ (native plugins)
    'c': 'cpp',
    'cpp': 'cpp',
    'cc': 'cpp',
    'h': 'cpp',
    'hpp': 'cpp',

    // HTML/CSS (web views)
    'html': 'html',
    'htm': 'html',
    'css': 'css',
    'scss': 'scss',
    'sass': 'sass',

    // Конфиги (git, docker)
    'gitignore': 'gitignore',
    'dockerfile': 'dockerfile',
    'dockerignore': 'gitignore',
    'toml': 'toml',
    'ini': 'ini',
    'env': 'ini', // .env files

    // Текстовые/логи
    'txt': 'plaintext',
    'log': 'plaintext',
  };

  /// Темы подсветки (light/dark)
  static const Map<bool, Map<String, TextStyle>> _themes = {
    true: vs2015Theme,   // Dark: VS2015 (dark syntax)
    false: githubTheme,  // Light: GitHub (light syntax)
  };

  /// Получение языка подсветки по пути файла
  /// Fallback на 'plaintext' если расширение неизвестно
  static String getLanguage(String filePath) {
    final extension = _extractExtension(filePath).toLowerCase();
    return _languageMap[extension] ?? _fallbackLanguage(extension);
  }

  /// Создание готового HighlightView виджета
  /// - code: текст кода
  /// - path: путь для определения языка
  /// - isDarkMode: true для темной темы (VS2015), false для светлой (GitHub)
  /// - style: базовый стиль шрифта
  static Widget buildHighlightView({
    required String code,
    required String path,
    required bool isDarkMode,
    TextStyle? textStyle,
    EdgeInsetsGeometry padding = const EdgeInsets.all(12),
  }) {
    final language = getLanguage(path);
    final theme = _themes[isDarkMode] ?? githubTheme;

    return HighlightView(
      code.isEmpty ? '// No content to preview\n// Start typing...' : code,
      language: language,
      theme: theme,
      padding: padding,
      textStyle: (textStyle ?? const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        fontFamilyFallback: ['Courier', 'monospace'],
      )).copyWith(backgroundColor: Colors.transparent),
    );
  }

  /// Проверка поддержки языка
  static bool isLanguageSupported(String language) {
    return _languageMap.values.contains(language.toLowerCase());
  }

  /// Фоллбек для неизвестных расширений
  /// Логика: если похоже на config/build — properties, иначе plaintext
  static String _fallbackLanguage(String extension) {
    if (extension.contains('gradle') || extension.contains('prop') || extension.contains('config')) {
      return 'properties';
    }
    if (extension.contains('log') || extension == '') {
      return 'plaintext';
    }
    return 'plaintext';
  }

  /// Извлечение расширения из полного пути файла
  static String _extractExtension(String path) {
    // Обработка множественных точек (e.g., file.tar.gz → gz)
    final parts = path.split('.');
    if (parts.length > 1) {
      return parts.last;
    }
    return '';
  }

  /// Кастомная функция для встраивания подсветки в Text (если не виджет)
  /// Возвращает FormattedText (для RichText)
  static InlineSpan? highlightInline(String code, String path, bool isDarkMode) {
    final language = getLanguage(path);
    if (!isLanguageSupported(language) || code.isEmpty) {
      return TextSpan(text: code);
    }

    // Используем highlighter напрямую (если нужно для inline)
    final highlight = _highlightText(code, language);
    return TextSpan(
      children: highlight.map((token) {
        final style = _getStyleForToken(token.type, isDarkMode);
        return TextSpan(text: token.content, style: style);
      }).toList(),
    );
  }

  /// Внутренняя подсветка (использует flutter_highlight под капотом)
  static List<HighlightToken> _highlightText(String code, String language) {
    final result = HighlightView(
      code,
      language: language,
      theme: _themes[true] ?? vs2015Theme, // Default dark
    )._tokens; // Примечание: flutter_highlight не экспозит tokens публично, это упрощение
               // В реальности использовать пакет с токенами или парсить вручную
    return []; // Placeholder: в prod использовать реальный токенизатор
  }

  /// Стиль для токена (упрощенный)
  static TextStyle _getStyleForToken(String tokenType, bool isDarkMode) {
    final baseStyle = TextStyle(fontFamily: 'RobotoMono', fontSize: 13);
    Color? color;

    switch (tokenType) {
      case 'keyword':
        color = isDarkMode ? const Color(0xFF569CD6) : const Color(0xFF0000FF);
        break;
      case 'string':
        color = isDarkMode ? const Color(0xFFCE9178) : const Color(0xFF008000);
        break;
      case 'comment':
        color = isDarkMode ? const Color(0xFF6A9955) : const Color(0xFF808080);
        break;
      case 'number':
        color = const Color(0xFFB5CEA8);
        break;
      case 'function':
        color = isDarkMode ? const Color(0xFFDCDCAA) : const Color(0xFF795E26);
        break;
      default:
        color = null; // Default text
    }

    return baseStyle.copyWith(color: color);
  }

  /// Список поддерживаемых языков (для UI)
  static List<String> get supportedLanguages => _languageMap.values.toSet().toList()..sort();

  /// Фильтрация по расширению (для валидации)
  static bool supportsExtension(String extension) {
    return _languageMap.containsKey(extension.toLowerCase());
  }

  /// Тестирование (статический метод)
  static void testHighlighter(String path, String sampleCode) {
    final language = getLanguage(path);
    print('Language for $path: $language (Supported: ${isLanguageSupported(language)})');
    if (sampleCode.isNotEmpty) {
      print('Preview tokens: ${_highlightText(sampleCode, language).length}');
    }
  }
}

/// Token модель (внутренняя для расширения flutter_highlight)
class HighlightToken {
  final String type;
  final String content;

  HighlightToken(this.type, this.content);
}
