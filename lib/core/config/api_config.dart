import 'app_config.dart';

/// Mutable runtime configuration shared between the UI and services.
class ApiConfig {
  String baseUrl;
  int parallelChunks;

  ApiConfig({
    String? baseUrl,
    int? parallelChunks,
  })  : baseUrl = baseUrl ?? AppConfig.defaultApiBaseUrl,
        parallelChunks = parallelChunks ?? AppConfig.defaultParallelChunks;
}
