sealed class Result<T, E> {
  const Result();

  factory Result.success(T value) = Success<T, E>;
  factory Result.error(E error) = Error<T, E>;

  R fold<R>(R Function(T success) onSuccess, R Function(E error) onError) {
    return switch (this) {
      Success(value: final value) => onSuccess(value),
      Error(error: final error) => onError(error),
    };
  }
}

class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

class Error<T, E> extends Result<T, E> {
  final E error;
  const Error(this.error);
}
