import 'package:satur_app/core/result/result.dart';
import 'package:satur_app/features/join_program/domain/email_address.dart';
import 'package:satur_app/features/join_program/domain/join_program_failure.dart';

/// Port for requesting access to the Satur benefits program.
///
/// Implementations:
/// - [StubJoinProgramRepository] — local no-op (current)
/// - future HTTP client against Satur API — swap in DI only
abstract interface class JoinProgramRepository {
  Future<Result<void, JoinProgramFailure>> requestAccess(EmailAddress email);
}
