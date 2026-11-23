/// Failures from [ApiClient]. Map at feature boundaries if needed.
sealed class ApiFailure {
  const ApiFailure();
}

final class ApiNetworkFailure extends ApiFailure {
  const ApiNetworkFailure([this.message]);
  final String? message;
}

final class ApiTimeoutFailure extends ApiFailure {
  const ApiTimeoutFailure();
}

final class ApiHttpFailure extends ApiFailure {
  const ApiHttpFailure({required this.statusCode, this.body});
  final int statusCode;
  final String? body;
}

final class ApiParseFailure extends ApiFailure {
  const ApiParseFailure([this.message]);
  final String? message;
}
