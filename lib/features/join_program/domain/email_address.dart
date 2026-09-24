import 'package:equatable/equatable.dart';

/// Validated email value object.
final class EmailAddress extends Equatable {
  const EmailAddress._(this.value);

  final String value;

  static final _pattern = RegExp(
    r"^[^@\s]+@[^@\s]+\.[^@\s]+$",
  );

  /// Returns null when [raw] is empty or not a valid email format.
  static EmailAddress? tryParse(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (!_pattern.hasMatch(normalized)) return null;
    return EmailAddress._(normalized);
  }

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
