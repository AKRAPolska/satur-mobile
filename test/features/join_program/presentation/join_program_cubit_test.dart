import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/join_program/domain/join_program.dart';
import 'package:satur_app/features/join_program/domain/join_program_failure.dart';
import 'package:satur_app/features/join_program/domain/join_program_repository.dart';
import 'package:satur_app/features/join_program/domain/email_address.dart';
import 'package:satur_app/features/join_program/presentation/join_program_cubit.dart';
import 'package:satur_app/features/join_program/presentation/join_program_state.dart';

class _MockRepo extends Mock implements JoinProgramRepository {}

void main() {
  late _MockRepo repo;
  late JoinProgramCubit cubit;

  setUp(() {
    repo = _MockRepo();
    cubit = JoinProgramCubit(JoinProgram(repo));
    registerFallbackValue(EmailAddress.tryParse('a@b.co')!);
  });

  tearDown(() => cubit.close());

  blocTest<JoinProgramCubit, JoinProgramState>(
    'emits invalidEmail when email is bad',
    build: () => cubit,
    act: (c) async {
      c.emailChanged('not-valid');
      await c.submit();
    },
    expect: () => [
      const JoinProgramSubmitting(),
      const JoinProgramInvalidEmail(),
    ],
    verify: (_) {
      verifyNever(() => repo.requestAccess(any()));
    },
  );

  blocTest<JoinProgramCubit, JoinProgramState>(
    'emits submitting then success for valid email',
    build: () => cubit,
    setUp: () {
      when(() => repo.requestAccess(any())).thenAnswer(
        (_) async => const Success(null),
      );
    },
    act: (c) async {
      c.emailChanged('ok@firma.pl');
      await c.submit();
    },
    expect: () => [
      const JoinProgramSubmitting(),
      const JoinProgramSuccess(),
    ],
  );

  blocTest<JoinProgramCubit, JoinProgramState>(
    'emits failure state when repository fails',
    build: () => cubit,
    setUp: () {
      when(() => repo.requestAccess(any())).thenAnswer(
        (_) async => const Failure(UnknownJoinFailure('boom')),
      );
    },
    act: (c) async {
      c.emailChanged('ok@firma.pl');
      await c.submit();
    },
    expect: () => [
      const JoinProgramSubmitting(),
      const JoinProgramFailureState(UnknownJoinFailure('boom')),
    ],
  );
}
