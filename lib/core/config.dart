/// Runtime config. Values come from `--dart-define` (see Makefile).
class AppConfig {
  AppConfig._();

  /// Backend Satur (Sylius) — default: local sibling project on :5051.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5051',
  );
}
