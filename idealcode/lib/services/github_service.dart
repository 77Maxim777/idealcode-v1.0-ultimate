import 'dart:convert';
import 'dart:io';

import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';
import '../data/models/project_model.dart';
import '../services/secure_storage_service.dart';
import '../utils/result.dart';

/// Сервис для интеграции с GitHub API
class GitHubService {
  static const String _userAgent = 'IdealCode-Mobile/1.0.0';
  static const int _timeoutSeconds = 30;

  /// Аутентификация через устройство (Device Flow)
  static Future<Result<String, String>> authenticateDeviceFlow() async {
    try {
      final github = GitHub(); // Без аутентификации для device flow

      // Запрос device code
      final deviceCode = await github.oauth.createDeviceCode('IdealCode');
      final deviceUri = Uri.parse(deviceCode.verificationUri!);

      // Открываем браузер
      if (await canLaunchUrl(deviceUri)) {
        await launchUrl(deviceUri, mode: LaunchMode.externalApplication);
      } else {
        return const Result.error('Cannot open browser. Please visit: ${deviceCode.verificationUri}');
      }

      debugPrint('User verification code: ${deviceCode.userCode}');

      // Получение токена с polling
      return await _pollForToken(github, deviceCode.deviceCode!, deviceCode.expiresIn!);
    } catch (e) {
      return Result.error('Authentication failed: $e');
    }
  }

  /// Получение токена через polling
  static Future<Result<String, String>> _pollForToken(
    GitHub github,
    String deviceCode,
    int expiresIn,
  ) async {
    final endTime = DateTime.now().add(Duration(seconds: expiresIn - 5)); // 5s margin
    const int intervalSeconds = 5;

    while (DateTime.now().isBefore(endTime)) {
      try {
        final tokenResponse = await github.oauth.getAccessToken(
          deviceCode: deviceCode,
          clientId: '', // Для public client
        );

        if (tokenResponse.accessToken != null) {
          final token = tokenResponse.accessToken!;
          await SecureStorageService.saveGitHubToken(token);
          return Result.success(token);
        }
      } catch (e) {
        // Продолжаем polling
        debugPrint('Polling... Error: $e');
      }

      await Future.delayed(const Duration(seconds: intervalSeconds));
    }

    return const Result.error('Authentication timeout. Please try again.');
  }

  /// Создание репозитория и коммит файлов проекта
  static Future<Result<String, String>> createRepositoryAndCommit(Project project) async {
    final tokenResult = await SecureStorageService.getGitHubToken();
    return tokenResult.fold(
      (error) => Result.error('GitHub token not available: $error'),
      (token) async {
        if (token == null || token.isEmpty) {
          return const Result.error('Empty GitHub token');
        }

        final authentication = Authentication.withToken(token);
        final github = GitHub(auth: authentication);

        try {
          // Валидация токена (проверка репозиториев)
          final currentUser = await github.users.getCurrentUser();
          debugPrint('Authenticated as: ${currentUser.login}');

          // Генерация имени репозитория
          final repoName = _generateRepoName(project);
          final repoSlug = RepositorySlug(
            currentUser.login,
            repoName,
          );

          // Проверка существования репозитория
          try {
            await github.repositories.getRepository(repoSlug);
            return Result.error('Repository $repoName already exists. Choose another name.');
          } catch (e) {
            if (e is GitHubException && e.statusCode != 404) {
              rethrow;
            }
            // 404 - OK, репозиторий не существует
          }

          // Создание репозитория
          final createRequest = CreateRepositoryRequest(
            repoName,
            name: project.title,
            description: project.description.isNotEmpty 
                ? project.description 
                : 'Project created with IdealCode Mobile Studio',
            private: false,
            autoInit: false, // Создадим вручную
            hasWiki: false,
            hasIssues: true,
            hasProjects: false,
          );

          final repository = await github.repositories.createRepository(createRequest);
          debugPrint('Created repository: ${repository.htmlUrl}');

          // Создание .gitignore и README
          await _createBaseFiles(github, repoSlug, project);

          // Коммит файлов проекта
          for (final file in project.files) {
            if (file.content.trim().isEmpty) continue;

            final commitResult = await _commitFile(
              github,
              repoSlug,
              file,
              project.title,
            );

            if (!commitResult) {
              return Result.error('Failed to commit file: ${file.path}');
            }
          }

          // Финальный коммит с сообщением
          await github.repositories.createCommit(
            repoSlug,
            CreateCommitRequest(
              message: 'Initial commit from IdealCode: ${project.filesCount}',
              tree: '', // HEAD
              parents: [''], // HEAD
            ),
          );

          final repoUrl = repository.htmlUrl!;
          return Result.success(repoUrl);
        } catch (e) {
          debugPrint('GitHub error: $e');
          return Result.error('GitHub operation failed: ${e.toString()}');
        }
      },
    );
  }

  /// Получение токена из хранилища
  static Future<Result<String?, String>> getToken() async {
    return await SecureStorageService.getGitHubToken();
  }

  /// Сохранение токена
  static Future<Result<void, String>> saveToken(String token) async {
    final validation = await SecureStorageService.validateGitHubToken(token);
    return validation.fold(
      (error) => Result.error(error),
      (_) => SecureStorageService.saveGitHubToken(token),
    );
  }

  /// Удаление токена
  static Future<Result<void, String>> deleteToken() async {
    return await SecureStorageService.deleteGitHubToken();
  }

  /// Приватные методы

  /// Генерация имени репозитория
  static String _generateRepoName(Project project) {
    final cleanTitle = project.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 'idealcode-${cleanTitle}-${project.id.substring(0, 8)}-$timestamp';
  }

  /// Создание базовых файлов (.gitignore, README)
  static Future<void> _createBaseFiles(GitHub github, RepositorySlug slug, Project project) async {
    // .gitignore
    final gitignoreContent = '''
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# IDE
.idea/
.vscode/settings.json
*.iml

# OS
.DS_Store
Thumbs.db

# Logs
*.log
    ''';

    await _createFile(github, slug, '.gitignore', gitignoreContent, 'Add .gitignore');

    // README.md
    final readmeContent = '''
# ${project.title}

Project created with **IdealCode Mobile Creative Studio** 🚀

## Description
${project.description.isEmpty ? 'A creative development project.' : project.description}

## Files
- **${project.filesCount}** files organized in canvas layout
- Dependencies visualized with connection lines

## How to Run
1. Clone this repository
2. Run \`flutter pub get\`
3. Run \`flutter run\`

Generated on ${DateTime.now().toIso8601String()}
    ''';

    await _createFile(github, slug, 'README.md', readmeContent, 'Initial README');
  }

  /// Коммит одного файла
  static Future<bool> _commitFile(
    GitHub github,
    RepositorySlug slug,
    ProjectFile file,
    String projectTitle,
  ) async {
    try {
      final content = utf8.encode(file.content);
      final base64Content = base64.encode(content);

      final cleanPath = p.normalize(file.path.replaceAll('\\', '/'));
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }

      // Создание дерева файлов
      final tree = [
        TreeEntry(
          path: cleanPath,
          mode: '100644', // file
          type: 'blob',
          content: base64Content,
        ),
      ];

      // Получение текущего commit
      final commits = await github.repositories.listCommits(slug).toList();
      final currentCommit = commits.first;

      // Создание нового commit
      await github.git.createTree(slug, tree, baseTree: currentCommit.sha);

      final newCommit = await github.git.createCommit(
        slug,
        CreateCommit(
          message: 'Add ${file.name} - ${file.annotation.substring(0, 50)}...',
          tree: '', // Последний tree
          parents: [currentCommit.sha!],
        ),
      );

      // Обновление ref (main)
      await github.git.updateReference(
        slug,
        'heads/main',
        newCommit.sha!,
      );

      debugPrint('Committed: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('Commit error for ${file.path}: $e');
      return false;
    }
  }

  /// Создание файла через API
  static Future<bool> _createFile(
    GitHub github,
    RepositorySlug slug,
    String path,
    String content,
    String message,
  ) async {
    try {
      final base64Content = base64.encode(utf8.encode(content));

      final request = CreateFileRequest(
        path,
        base64Content,
        message: message,
        branch: 'main',
      );

      await github.repositories.createFile(slug, request);
      return true;
    } catch (e) {
      debugPrint('Create file error $path: $e');
      return false;
    }
  }

  /// Проверка прав токена
  static Future<Result<Map<String, dynamic>, String>> checkTokenScopes(String token) async {
    try {
      final authentication = Authentication.withToken(token);
      final github = GitHub(auth: authentication);

      // Проверяем доступ к репозиториям
      final repos = await github.repositories.listRepositoriesForAuthenticatedUser().toList();
      final scopes = await _getScopesFromToken(github);

      return Result.success({
        'valid': true,
        'user': await github.users.getCurrentUser(),
        'scopes': scopes,
        'repoCount': repos.length,
      });
    } catch (e) {
      return Result.error('Token validation failed: $e');
    }
  }

  static Future<List<String>> _getScopesFromToken(GitHub github) async {
    // Получение заголовка Authorization для scopes
    final response = await github.httpClient.head(Uri.parse(AppConstants.githubApiUrl));
    final authHeader = response.headers.value('X-OAuth-Scopes');
    return authHeader?.split(',')?.map((s) => s.trim()).toList() ?? [];
  }

  /// Экспорт проекта как ZIP (альтернатива)
  static Future<Result<String, String>> exportToZip(Project project) async {
    try {
      // Создаем временную директорию
      final tempDir = Directory.systemTemp.createTempSync('idealcode_export');
      
      // Создаем структуру файлов
      await _createProjectStructure(tempDir.path, project);

      // ZIP архив
      final zipPath = p.join(tempDir.path, '${project.title.replaceAll(' ', '_')}.zip');
      await _zipDirectory(tempDir.path, zipPath);

      // Возвращаем путь к ZIP
      return Result.success(zipPath);
    } catch (e) {
      return Result.error('ZIP export failed: $e');
    }
  }

  // Приватные методы для ZIP (требует dart:io)
  static Future<void> _createProjectStructure(String basePath, Project project) async {
    // Создаем .gitignore и README как выше
    await Directory(basePath).create(recursive: true);

    // Файлы проекта
    for (final file in project.files) {
      final filePath = p.join(basePath, file.path);
      final dir = p.dirname(filePath);
      await Directory(dir).create(recursive: true);
      await File(filePath).writeAsString(file.content);
    }
  }

  static Future<void> _zipDirectory(String dirPath, String zipPath) async {
    // Используем process для zip (кросс-платформенный, но требует zip утилиты)
    final process = await Process.run('zip', ['-r', zipPath, '.'],
      workingDirectory: dirPath,
    );

    if (process.exitCode != 0) {
      throw Exception('ZIP creation failed: ${process.stderr}');
    }
  }

  /// Тестирование сервиса
  static Future<void> testService() async {
    final tokenResult = await getToken();
    tokenResult.fold(
      (error) => debugPrint('Test failed: $error'),
      (token) async {
        final scopes = await checkTokenScopes(token!);
        scopes.fold(
          (error) => debugPrint('Scopes check failed: $error'),
          (info) => debugPrint('Test success: ${info['repoCount']} repos'),
        );
      },
    );
  }
}
