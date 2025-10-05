class AppConstants {
  AppConstants._();

  static const String projectsBoxName = 'projects_box';
  static const String githubTokenKey = 'github_token_key';

  static const String githubApiUrl = 'https://api.github.com';
  static const String githubRepoUrl = 'https://github.com/[username]/idealcode-v1.0-ultimate';
}

class AppRoutes {
  AppRoutes._();
  static const String home = '/';
  static const String create = '/create';
  static const String project = '/project/:id';
  static const String editor = '/project/:id/editor/:fileId';
  static const String settings = '/settings';
}
