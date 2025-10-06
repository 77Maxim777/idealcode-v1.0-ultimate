/// Application constants
class AppConstants {
  AppConstants._();
  
  // Storage
  static const String projectsBoxName = 'projects_box';
  static const String settingsBoxName = 'settings_box';
  static const String githubTokenKey = 'github_token';
  
  // GitHub
  static const String githubApiUrl = 'https://api.github.com';
  static const String githubRepoTemplate = 'https://github.com/{username}/{repo}';
  static const String defaultUsername = 'idealcode';
  static const String defaultRepoName = 'idealcode-mobile-v1.0';
  
  // App
  static const String appName = 'IdealCode';
  static const String appVersion = '1.0.0';
  static const double canvasItemSize = 120.0;
  static const double canvasItemHeight = 80.0;
  static const double connectionLineWidth = 2.0;
  
  // Colors
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color secondaryColor = Color(0xFF625B71);
  static const Color surfaceColor = Color(0xFFFFFBFE);
  
  // Paths
  static const String assetsPath = 'assets/images/';
  static const String iconPath = '${assetsPath}app_icon.png';
}

/// App routes
class AppRoutes {
  AppRoutes._();
  
  static const String splash = '/splash';
  static const String home = '/';
  static const String createProject = '/create';
  static const String project = '/project/:id';
  static const String projectCanvas = '/project/:id/canvas';
  static const String projectEditor = '/project/:id/editor/:fileId';
  static const String tzEditor = '/project/:id/tz';
  static const String ptzImport = '/project/:id/ptz-import';
  static const String githubExport = '/project/:id/github-export';
  static const String settings = '/settings';
  static const String about = '/about';
}

/// File extensions and types
class FileExtensions {
  FileExtensions._();
  
  static const List<String> configFiles = [
    '.yaml', '.yml', '.json', '.xml', '.gradle', '.properties'
  ];
  
  static const List<String> codeFiles = [
    '.dart', '.kt', '.java', '.js', '.ts', '.py', '.cpp', '.h'
  ];
  
  static const List<String> resourceFiles = [
    '.png', '.jpg', '.jpeg', '.gif', '.svg', '.mp4', '.mp3', '.pdf'
  ];
  
  static const List<String> docFiles = [
    '.md', '.txt', '.docx', '.html'
  ];
}

/// Canvas layout constants
class CanvasLayout {
  CanvasLayout._();
  
  static const double startX = 50.0;
  static const double startY = 50.0;
  static const double stepX = 160.0;
  static const double stepY = 100.0;
  static const int columns = 6;
  static const double gridMargin = 20.0;
  static const double canvasMinWidth = 800.0;
  static const double canvasMinHeight = 600.0;
}
