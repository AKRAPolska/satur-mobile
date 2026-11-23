import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/join_program/domain/email_address.dart';
import 'package:satur_app/features/join_program/domain/join_program_failure.dart';
import 'package:satur_app/features/join_program/domain/join_program_repository.dart';

/// Application use case: validate email and request program access.
final class JoinProgram {
  const JoinProgram(this._repository);

  final JoinProgramRepository _repository;

  Future<Result<void, JoinProgramFailure>> call(String rawEmail) async {
    final email = EmailAddress.tryParse(rawEmail);
    if (email == null) {
      return const Failure(InvalidEmailFailure());
    }
    return _repository.requestAccess(email);
  }
}
