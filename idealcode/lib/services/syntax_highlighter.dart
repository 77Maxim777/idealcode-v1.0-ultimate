class SyntaxHighlighter {
  static String getLanguage(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'dart':
        return 'dart';
      case 'kt':
      case 'java':
        return 'kotlin';
      case 'xml':
        return 'xml';
      case 'json':
        return 'json';
      case 'yaml':
      case 'yml':
        return 'yaml';
      case 'md':
        return 'markdown';
      case 'gradle':
        return 'gradle';
      case 'properties':
        return 'properties';
      case 'txt':
        return 'plaintext';
      default:
        return 'plaintext';
    }
  }
}
