import '../../core/config/app_config.dart';
import '../models/download_task.dart';
import '../models/extract_result.dart';
import '../services/api_client.dart';
import '../services/downloader_service.dart';
import '../services/storage_service.dart';

/// Single entry point for extract + download operations used by controllers.
class MediaRepository {
  MediaRepository({
    required ApiClient api,
    required DownloaderService downloader,
  })  : _api = api,
        _downloader = downloader;

  final ApiClient _api;
  final DownloaderService _downloader;

  Future<ExtractResult> extract(
    String url, {
    bool audioOnly = false,
    String? preferredQuality,
  }) {
    return _api.extract(
      url,
      audioOnly: audioOnly,
      preferredQuality: preferredQuality,
    );
  }

  Future<DownloadTask> download({
    required String url,
    required String fileName,
    String? audioUrl,
    Map<String, String>? headers,
    Map<String, String>? audioHeaders,
    bool isHls = false,
    int parallelChunks = AppConfig.defaultParallelChunks,
    String? directory,
  }) async {
    final dir = directory ?? (await StorageService.instance.downloadsDir()).path;
    return _downloader.start(
      DownloadRequest(
        url: url,
        audioUrl: audioUrl,
        headers: headers,
        audioHeaders: audioHeaders,
        fileName: fileName,
        saveDirectory: dir,
        parallelChunks: parallelChunks,
        isHls: isHls,
      ),
    );
  }
}
