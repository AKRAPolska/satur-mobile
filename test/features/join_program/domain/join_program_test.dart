import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/join_program/domain/email_address.dart';
import 'package:satur_app/features/join_program/domain/join_program.dart';
import 'package:satur_app/features/join_program/domain/join_program_failure.dart';
import 'package:satur_app/features/join_program/domain/join_program_repository.dart';

class _MockRepo extends Mock implements JoinProgramRepository {}

void main() {
  group('EmailAddress', () {
    test('parses and normalizes valid email', () {
      final email = EmailAddress.tryParse('  User@Firm.PL ');
      expect(email, isNotNull);
      expect(email!.value, 'user@firm.pl');
    });

    test('rejects empty and invalid', () {
      expect(EmailAddress.tryParse(''), isNull);
      expect(EmailAddress.tryParse('not-an-email'), isNull);
      expect(EmailAddress.tryParse('@firm.pl'), isNull);
    });
  });

  group('JoinProgram', () {
    late _MockRepo repo;
    late JoinProgram useCase;

    setUp(() {
      repo = _MockRepo();
      useCase = JoinProgram(repo);
      registerFallbackValue(EmailAddress.tryParse('a@b.co')!);
    });

    test('returns InvalidEmailFailure without calling repository', () async {
      final result = await useCase('bad');
      expect(result, isA<Failure<void, JoinProgramFailure>>());
      final failure = (result as Failure<void, JoinProgramFailure>).error;
      expect(failure, isA<InvalidEmailFailure>());
      verifyNever(() => repo.requestAccess(any()));
    });

    test('delegates to repository for valid email', () async {
      when(() => repo.requestAccess(any())).thenAnswer(
        (_) async => const Success(null),
      );

      final result = await useCase('ok@firma.pl');
      expect(result, isA<Success<void, JoinProgramFailure>>());
      verify(() => repo.requestAccess(any())).called(1);
    });
  });
}
