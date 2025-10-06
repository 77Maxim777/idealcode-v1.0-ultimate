import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../core/constants/app_constants.dart';
import '../utils/result.dart';

/// Secure storage service for sensitive data like tokens
class SecureStorageService {
  SecureStorageService._();
  
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      ignoreErrors: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainItemAccessibility.first_unlock_this_device,
    ),
  );
  
  static const String _prefix = 'idealcode_';
  static const String _version = 'v1_0';
  
  // GitHub related
  static Future<Result<String?, String>> getGitHubToken() async {
    return await _readSecure(_getGitHubTokenKey());
  }
  
  static Future<Result<void, String>> saveGitHubToken(String token) async {
    if (token.isEmpty) {
      return const Result.error('Token cannot be empty');
    }
    
    // Basic token validation
    if (!token.startsWith('ghp_') && !token.startsWith('github_pat_')) {
      return const Result.error('Invalid GitHub token format');
    }
    
    return await _writeSecure(_getGitHubTokenKey(), token);
  }
  
  static Future<Result<void, String>> deleteGitHubToken() async {
    return await _deleteSecure(_getGitHubTokenKey());
  }
  
  static bool get hasGitHubToken => _storage.read(key: _getGitHubTokenKey()) != null;
  
  // App settings
  static Future<Result<String?, String>> getAppSetting(String key) async {
    return await _readSecure(_getAppSettingKey(key));
  }
  
  static Future<Result<void, String>> saveAppSetting(String key, String value) async {
    return await _writeSecure(_getAppSettingKey(key), value);
  }
  
  static Future<Result<void, String>> deleteAppSetting(String key) async {
    return await _deleteSecure(_getAppSettingKey(key));
  }
  
  // User preferences
  static Future<Result<String?, String>> getUserPreference(String key) async {
    return await _readSecure(_getUserPreferenceKey(key));
  }
  
  static Future<Result<void, String>> saveUserPreference(String key, String value) async {
    return await _writeSecure(_getUserPreferenceKey(key), value);
  }
  
  static Future<Result<void, String>> deleteUserPreference(String key) async {
    return await _deleteSecure(_getUserPreferenceKey(key));
  }
  
  // Device info
  static Future<Result<String, String>> getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return Result.success(androidInfo.id);
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return Result.success(iosInfo.identifierForVendor ?? 'unknown');
      }
      return Result.success('unknown_device');
    } catch (e) {
      return Result.success('fallback_device_${DateTime.now().millisecondsSinceEpoch}');
    }
  }
  
  // Security methods
  static Future<bool> isStorageAvailable() async {
    try {
      final testKey = '$_prefix$_version_test';
      await _storage.write(key: testKey, value: 'test');
      await _storage.delete(key: testKey);
      return true;
    } catch (e) {
      debugPrint('Secure storage not available: $e');
      return false;
    }
  }
  
  static Future<Result<void, String>> clearAll() async {
    try {
      await _storage.deleteAll();
      return const Result.success(null);
    } catch (e) {
      return Result.error('Failed to clear secure storage: $e');
    }
  }
  
  static Future<Result<Map<String, String>, String>> getAllKeys() async {
    try {
      final allData = await _storage.readAll();
      final filtered = <String, String>{};
      
      for (final entry in allData.entries) {
        if (entry.key.startsWith(_prefix)) {
          filtered[entry.key] = entry.value ?? '';
        }
      }
      
      return Result.success(filtered);
    } catch (e) {
      return Result.error('Failed to get all keys: $e');
    }
  }
  
  // Private methods
  static String _getGitHubTokenKey() => '$_prefix$_version${AppConstants.githubTokenKey}';
  
  static String _getAppSettingKey(String key) => '$_prefix$_version$app_setting_$key';
  
  static String _getUserPreferenceKey(String key) => '$_prefix$_version$user_pref_$key';
  
  static Future<Result<String?, String>> _readSecure(String key) async {
    try {
      // Add device-specific suffix for better security
      final deviceIdResult = await getDeviceId();
      final deviceSuffix = deviceIdResult.isSuccess ? '_${deviceIdResult.value}' : '';
      final secureKey = '$key$deviceSuffix';
      
      final value = await _storage.read(key: secureKey);
      return Result.success(value);
    } catch (e) {
      debugPrint('Error reading secure storage key $key: $e');
      return Result.error('Failed to read from secure storage: $e');
    }
  }
  
  static Future<Result<void, String>> _writeSecure(String key, String value) async {
    try {
      // Add device-specific suffix for better security
      final deviceIdResult = await getDeviceId();
      final deviceSuffix = deviceIdResult.isSuccess ? '_${deviceIdResult.value}' : '';
      final secureKey = '$key$deviceSuffix';
      
      await _storage.write(
        key: secureKey, 
        value: value,
        aOptions: const AndroidOptions(encryptedSharedPreferences: true),
      );
      
      // Also store without device suffix as backup
      await _storage.write(key: key, value: value);
      
      return const Result.success(null);
    } catch (e) {
      debugPrint('Error writing to secure storage key $key: $e');
      return Result.error('Failed to write to secure storage: $e');
    }
  }
  
  static Future<Result<void, String>> _deleteSecure(String key) async {
    try {
      // Delete both versions (with and without device suffix)
      final deviceIdResult = await getDeviceId();
      final deviceSuffix = deviceIdResult.isSuccess ? '_${deviceIdResult.value}' : '';
      final secureKey = '$key$deviceSuffix';
      
      await _storage.delete(key: key);
      await _storage.delete(key: secureKey);
      
      return const Result.success(null);
    } catch (e) {
      debugPrint('Error deleting from secure storage key $key: $e');
      return Result.error('Failed to delete from secure storage: $e');
    }
  }
  
  // Token validation
  static Future<Result<bool, String>> validateGitHubToken(String token) async {
    if (token.isEmpty) {
      return const Result.error('Token is empty');
    }
    
    if (!token.startsWith('ghp_') && !token.startsWith('github_pat_')) {
      return const Result.error('Invalid token format. Must start with ghp_ or github_pat_');
    }
    
    // Basic length check
    if (token.length < 20 || token.length > 100) {
      return const Result.error('Token length is invalid');
    }
    
    return const Result.success(true);
  }
  
  // Migration
  static Future<Result<void, String>> migrateTokens() async {
    try {
      // Check for old token format
      const oldTokenKey = 'github_token';
      final oldToken = await _storage.read(key: oldTokenKey);
      
      if (oldToken != null && oldToken.isNotEmpty) {
        // Migrate to new format
        final result = await saveGitHubToken(oldToken);
        if (result.isSuccess) {
          // Delete old token
          await _storage.delete(key: oldTokenKey);
        }
        return result;
      }
      
      return const Result.success(null);
    } catch (e) {
      return Result.error('Token migration failed: $e');
    }
  }
}
