import 'package:equatable/equatable.dart';

import '../domain/join_program_failure.dart';

sealed class JoinProgramState extends Equatable {
  const JoinProgramState();

  @override
  List<Object?> get props => [];
}

final class JoinProgramIdle extends JoinProgramState {
  const JoinProgramIdle();
}

final class JoinProgramInvalidEmail extends JoinProgramState {
  const JoinProgramInvalidEmail();
}

final class JoinProgramSubmitting extends JoinProgramState {
  const JoinProgramSubmitting();
}

final class JoinProgramSuccess extends JoinProgramState {
  const JoinProgramSuccess();
}

final class JoinProgramFailureState extends JoinProgramState {
  const JoinProgramFailureState(this.failure);
  final JoinProgramFailure failure;

  @override
  List<Object?> get props => [failure];
}
