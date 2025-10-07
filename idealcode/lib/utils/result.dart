import 'dart:convert';

/// Кастомный тип Result для функциональной обработки ошибок
/// Использует sealed class для паттерна Result<T, E>
sealed class Result<T, E> {
  const Result();

  /// Создание успешного результата
  factory Result.success(T value) = Success<T, E>;

  /// Создание ошибочного результата
  factory Result.error(E error) = Error<T, E>;

  /// Обработка результата через fold (функциональный стиль)
  R fold<R>(
    R Function(T success) onSuccess,
    R Function(E error) onError,
  ) {
    return switch (this) {
      Success(value: final value) => onSuccess(value),
      Error(error: final error) => onError(error),
    };
  }

  /// Проверка на успех
  bool get isSuccess => this is Success<T, E>;

  /// Проверка на ошибку
  bool get isError => this is Error<T, E>;

  /// Получить значение (null если ошибка)
  T? get valueOrNull => switch (this) {
        Success(value: final value) => value,
        Error() => null,
      };

  /// Получить ошибку (null если успех)
  E? get errorOrNull => switch (this) {
        Success() => null,
        Error(error: final error) => error,
      };

  /// Преобразование в строку для отладки
  @override
  String toString() {
    return switch (this) {
      Success(value: final value) => 'Success($value)',
      Error(error: final error) => 'Error($error)',
    };
  }

  /// JSON сериализация
  Map<String, dynamic> toJson(Object Function(T) encodeValue, Object Function(E) encodeError) {
    return switch (this) {
      Success(value: final value) => {
          'type': 'success',
          'value': encodeValue(value),
        },
      Error(error: final error) => {
          'type': 'error',
          'error': encodeError(error),
        },
    };
  }
}

/// Успешный результат
class Success<T, E> extends Result<T, E> {
  final T value;

  const Success(this.value);
}

/// Ошибочный результат
class Error<T, E> extends Result<T, E> {
  final E error;

  const Error(this.error);
}

/// Удобные расширения для Result
extension ResultExtensions<T, E> on Result<T, E> {
  /// Map для успешного значения
  Result<R, E> map<R>(R Function(T) mapper) {
    return switch (this) {
      Success(value: final value) => Result.success(mapper(value)),
      Error(error: final error) => Result.error(error),
    };
  }

  /// Flat map для успешного значения
  Result<R, E> flatMap<R>(Result<R, E> Function(T) mapper) {
    return switch (this) {
      Success(value: final value) => mapper(value),
      Error(error: final error) => Result.error(error),
    };
  }

  /// Восстановление из ошибки по умолчанию
  Result<T, E> recover(T Function(E) recoverer) {
    return switch (this) {
      Success(value: final value) => Result.success(value),
      Error(error: final error) => Result.success(recoverer(error)),
    };
  }

  /// Игнорирование результата (fire and forget)
  void ignore() {
    // Просто ничего не делаем, для совместимости
  }

  /// Преобразование в Future (для async)
  Future<T> toFutureOrElse({T Function(E)? orElse}) async {
    return fold(
      (success) => success,
      (error) => orElse != null ? orElse(error) : throw Exception(error.toString()),
    );
  }
}

/// Утилиты для работы с Result
class ResultUtils {
  /// Создание Result из nullable значения
  static Result<T, String> fromNullable<T>(T? value, String errorMessage) {
    if (value == null) {
      return Result.error(errorMessage);
    }
    return Result.success(value);
  }

  /// Создание Result из исключения
  static Result<T, String> fromException<T>(Future<T> future) async {
    try {
      final value = await future;
      return Result.success(value);
    } catch (e, stackTrace) {
      debugPrint('Exception caught: $e\n$stackTrace');
      return Result.error(e.toString());
    }
  }

  /// Сериализация Result в JSON
  static String toJsonString<T, E>(Result<T, E> result) {
    return jsonEncode(result.toJson(
      (value) => value.toString(),
      (error) => error.toString(),
    ));
  }

  /// Десериализация из JSON (упрощенная)
  static Result<T, String> fromJsonString<T>(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final type = json['type'] as String;

      return switch (type) {
        'success' => Result.success(json['value'] as T),
        'error' => Result.error(json['error'] as String),
        _ => const Result.error('Invalid result type'),
      };
    } catch (e) {
      return Result.error('Failed to parse JSON: $e');
    }
  }
}
