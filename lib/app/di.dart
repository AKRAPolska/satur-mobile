import 'package:http/http.dart' as http;

import 'package:satur_app/core/config.dart';
import 'package:satur_app/core/network/api_client.dart';
import 'package:satur_app/features/catalog/data/http_catalog_repository.dart';
import 'package:satur_app/features/catalog/domain/catalog_repository.dart';
import 'package:satur_app/features/join_program/data/stub_join_program_repository.dart';
import 'package:satur_app/features/join_program/domain/join_program.dart';
import 'package:satur_app/features/join_program/domain/join_program_repository.dart';

/// Manual composition root. Swap [JoinProgramRepository] when HTTP is ready.
final class AppDependencies {
  AppDependencies._({
    required this.httpClient,
    required this.apiClient,
    required this.catalogRepository,
    required this.joinProgramRepository,
    required this.joinProgram,
  });

  final http.Client httpClient;
  final ApiClient apiClient;
  final CatalogRepository catalogRepository;
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
      catalogRepository: HttpCatalogRepository(apiClient),
      joinProgramRepository: repository,
      joinProgram: JoinProgram(repository),
    );
  }
}
