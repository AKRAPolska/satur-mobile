import '../../../core/result/result.dart';
import '../domain/email_address.dart';
import '../domain/join_program_failure.dart';
import '../domain/join_program_repository.dart';

/// No-network stub. Simulates latency; does not send email or hit Satur API.
///
/// Replace with an HTTP implementation when the enroll endpoint is ready —
/// keep the [JoinProgramRepository] contract unchanged.
final class StubJoinProgramRepository implements JoinProgramRepository {
  StubJoinProgramRepository({
    this.delay = const Duration(milliseconds: 300),
    this.shouldFail = false,
  });

  final Duration delay;
  final bool shouldFail;

  /// Last email passed to [requestAccess] — useful in tests / debug.
  EmailAddress? lastRequestedEmail;

  @override
  Future<Result<void, JoinProgramFailure>> requestAccess(
    EmailAddress email,
  ) async {
    lastRequestedEmail = email;
    await Future<void>.delayed(delay);
    if (shouldFail) {
      return const Failure(UnknownJoinFailure('stub failure'));
    }
    // Intentionally empty: path is ready; no mail / HTTP yet.
    return const Success(null);
  }
}
