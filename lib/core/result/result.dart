/// Lightweight Result type for domain boundaries (no third-party Either).
sealed class Result<T, E> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  });
}

final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) =>
      success(value);
}

final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) =>
      failure(error);
}
