import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../utils/result.dart';

class SecureStorageService {
  const SecureStorageService._();

  static const _storage = FlutterSecureStorage();

  static Future<Result<String?, String>> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      return Result.success(value);
    } catch (e) {
      return Result.error('Failed to read from secure storage: $e');
    }
  }

  static Future<Result<void, String>> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to write to secure storage: $e');
    }
  }

  static Future<Result<void, String>> delete(String key) async {
    try {
      await _storage.delete(key: key);
      return Result.success(null);
    } catch (e) {
      return Result.error('Failed to delete from secure storage: $e');
    }
  }
}
