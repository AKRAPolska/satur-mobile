import '../../../core/result/result.dart';
import 'email_address.dart';
import 'join_program_failure.dart';

/// Port for requesting access to the Satur benefits program.
///
/// Implementations:
/// - [StubJoinProgramRepository] — local no-op (current)
/// - future HTTP client against Satur API — swap in DI only
abstract interface class JoinProgramRepository {
  Future<Result<void, JoinProgramFailure>> requestAccess(EmailAddress email);
}
