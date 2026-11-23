import 'package:equatable/equatable.dart';

/// Domain failures for join-program flow.
/// [network] / [unknown] reserved for a future HTTP repository.
sealed class JoinProgramFailure extends Equatable {
  const JoinProgramFailure();

  @override
  List<Object?> get props => [];
}

final class InvalidEmailFailure extends JoinProgramFailure {
  const InvalidEmailFailure();
}

final class NetworkFailure extends JoinProgramFailure {
  const NetworkFailure([this.message]);
  final String? message;

  @override
  List<Object?> get props => [message];
}

final class UnknownJoinFailure extends JoinProgramFailure {
  const UnknownJoinFailure([this.message]);
  final String? message;

  @override
  List<Object?> get props => [message];
}
