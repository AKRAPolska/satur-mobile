import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../core/network/api_client.dart';
import '../features/join_program/data/stub_join_program_repository.dart';
import '../features/join_program/domain/join_program.dart';
import '../features/join_program/domain/join_program_repository.dart';

/// Manual composition root. Swap [JoinProgramRepository] when HTTP is ready.
final class AppDependencies {
  AppDependencies._({
    required this.httpClient,
    required this.apiClient,
    required this.joinProgramRepository,
    required this.joinProgram,
  });

  final http.Client httpClient;
  final ApiClient apiClient;
  final JoinProgramRepository joinProgramRepository;
  final JoinProgram joinProgram;

  factory AppDependencies.create() {
    final httpClient = http.Client();
    final apiClient = ApiClient(
      httpClient: httpClient,
      baseUrl: AppConfig.apiBaseUrl,
    );
    final repository = StubJoinProgramRepository();
    return AppDependencies._(
      httpClient: httpClient,
      apiClient: apiClient,
      joinProgramRepository: repository,
      joinProgram: JoinProgram(repository),
    );
  }
}
