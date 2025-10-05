import 'dart:convert';

import 'package:github/github.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';
import '../data/models/project_model.dart';
import '../services/secure_storage_service.dart';
import '../utils/result.dart';

class GitHubService {
  const GitHubService._();

  static Future<Result<bool, String>> authenticate() async {
    final uri = Uri.parse('${AppConstants.githubApiUrl}/settings/tokens');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return const Result.success(true);
  }

  static Future<Result<String?, String>> getToken() async {
    return await SecureStorageService.read(AppConstants.githubTokenKey);
  }

  static Future<Result<void, String>> saveToken(String token) async {
    return await SecureStorageService.write(AppConstants.githubTokenKey, token);
  }

  static Future<Result<void, String>> createRepositoryAndCommit(
    Project project,
  ) async {
    final tokenResult = await getToken();
    return tokenResult.fold(
      (error) => Result.error('GitHub token not found: $error'),
      (token) async {
        if (token == null) return const Result.error('GitHub token is null');
        
        final github = GitHub(auth: Authentication.withToken(token));
        
        try {
          // Create repository
          final slug = RepositorySlug.full('idealcode-${project.id}');
          final repo = await github.repositories.createRepository(
            slug,
            CreateRepositoryRequest(
              project.title, 
              description: project.description ?? 'Created with IdealCode',
              private: false,
            ),
          );
          
          // Create files
          for (final file in project.files) {
            final content = base64.encode(utf8.encode(file.content));
            final path = file.path.startsWith('/') ? file.path.substring(1) : file.path;
            
            await github.repositories.createFile(
              slug,
              CreateFileRequest(
                path,
                content,
                message: 'Initial commit: ${file.name}',
                branch: 'main',
              ),
            );
          }
          
          return const Result.success(null);
        } catch (e) {
          return Result.error('GitHub operation failed: $e');
        }
      },
    );
  }
}
