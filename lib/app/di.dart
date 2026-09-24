import '../features/join_program/data/stub_join_program_repository.dart';
import '../features/join_program/domain/join_program.dart';
import '../features/join_program/domain/join_program_repository.dart';

/// Manual composition root. Swap [JoinProgramRepository] when HTTP is ready.
final class AppDependencies {
  AppDependencies._({
    required this.joinProgramRepository,
    required this.joinProgram,
  });

  final JoinProgramRepository joinProgramRepository;
  final JoinProgram joinProgram;

  factory AppDependencies.create() {
    final repository = StubJoinProgramRepository();
    return AppDependencies._(
      joinProgramRepository: repository,
      joinProgram: JoinProgram(repository),
    );
  }
}
