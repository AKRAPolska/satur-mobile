import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/join_program.dart';
import '../domain/join_program_failure.dart';
import 'join_program_state.dart';

final class JoinProgramCubit extends Cubit<JoinProgramState> {
  JoinProgramCubit(this._joinProgram) : super(const JoinProgramIdle());

  final JoinProgram _joinProgram;

  String _email = '';

  void emailChanged(String value) {
    _email = value;
    if (state is JoinProgramInvalidEmail ||
        state is JoinProgramSuccess ||
        state is JoinProgramFailureState) {
      emit(const JoinProgramIdle());
    }
  }

  Future<void> submit() async {
    emit(const JoinProgramSubmitting());
    final result = await _joinProgram(_email);
    result.when(
      success: (_) => emit(const JoinProgramSuccess()),
      failure: (error) {
        if (error is InvalidEmailFailure) {
          emit(const JoinProgramInvalidEmail());
        } else {
          emit(JoinProgramFailureState(error));
        }
      },
    );
  }
}
