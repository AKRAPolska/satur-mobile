import '../../../core/result/result.dart';
import 'email_address.dart';
import 'join_program_failure.dart';
import 'join_program_repository.dart';

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
