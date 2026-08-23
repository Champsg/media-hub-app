import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/file_utils.dart';
import '../../core/utils/url_utils.dart';
import '../models/download_task.dart';
import 'hls_stitcher.dart';
import 'media_scanner.dart';

class _SpeedSample {
  _SpeedSample(this.at, this.bytes);

  final DateTime at;
  final int bytes;
}

class ProbeResult {
  const ProbeResult({
    required this.totalBytes,
    required this.acceptRanges,
    required this.isHlsPlaylist,
  });

  final int totalBytes;
  final bool acceptRanges;
  final bool isHlsPlaylist;
}

/// Chunked download manager with pause / resume, parallel range requests and
/// a broadcast progress stream. HLS playlists are routed to the stitcher.
class DownloaderService {
  DownloaderService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(minutes: 30),
                followRedirects: true,
                maxRedirects: 5,
              ),
            );

  final Dio _dio;
  final HlsStitcher _hlsStitcher = HlsStitcher();
  final StreamController<DownloadProgress> _progressController =
      StreamController<DownloadProgress>.broadcast();

  final Map<String, DownloadTask> _tasks = {};
  final Map<String, DownloadRequest> _requests = {};
  final Map<String, List<CancelToken>> _chunkTokens = {};
  final Map<String, List<int>> _chunkBytes = {};
  final Map<String, _SpeedSample> _samples = {};
  final Set<String> _paused = {};

  static const int requestChunkBytes = 4 * 1024 * 1024;

  Stream<DownloadProgress> get progressStream =>
      _progressController.stream;
  List<DownloadTask> get tasks => _tasks.values.toList(growable: false);
  DownloadTask? taskById(String id) => _tasks[id];

  Future<DownloadTask> start(DownloadRequest request) async {
    final id = const Uuid().v4();
    final directory = Directory(request.saveDirectory);
    await directory.create(recursive: true);
    final fileName = request.isHls
        ? FileUtils.hlsFileName(request.fileName)
        : FileUtils.sanitizeFileName(request.fileName);
    final savePath = p.join(directory.path, fileName);

    final task = DownloadTask(
      id: id,
      url: request.url,
      fileName: fileName,
      savePath: savePath,
      isHls: request.isHls,
      totalChunks: request.parallelChunks,
    );
    _tasks[id] = task;
    _requests[id] = request;
    _emit(task);
    unawaited(_run(task));
    return task;
  }

  Future<void> pause(String id) async {
    final task = _tasks[id];
    if (task == null || task.status != DownloadStatus.running) return;
    _paused.add(id);
    _chunkTokens[id]?.forEach((token) => token.cancel());
  }

  Future<void> resume(String id) async {
    final task = _tasks[id];
    if (task == null || task.status != DownloadStatus.paused) return;
    _paused.remove(id);
    await _run(task);
  }

  Future<void> cancel(String id) async {
    final task = _tasks[id];
    if (task == null) return;
    final running = task.status == DownloadStatus.running;
    _paused.remove(id);
    if (running) {
      _chunkTokens[id]?.forEach((token) => token.cancel());
    } else {
      task.status = DownloadStatus.canceled;
      await _cleanupParts(task);
      await _deleteIfExists(task.savePath);
      _emit(task);
    }
  }

  Future<void> retry(String id) async {
    final task = _tasks[id];
    final request = _requests[id];
    if (task == null || request == null) return;
    await cancel(id);
    _tasks.remove(id);
    await start(request);
  }

  /// Removes the task from memory (files are kept on disk).
  void remove(String id) {
    _tasks.remove(id);
    _requests.remove(id);
    _chunkBytes.remove(id);
    _samples.remove(id);
  }

  Future<void> _run(DownloadTask task) async {
    final request = _requests[task.id]!;
    task.status = DownloadStatus.running;
    _emit(task);
    try {
      final probe = await _probe(task.url, request.headers);
      task.totalBytes = probe.totalBytes;
      final isHls = task.isHls || probe.isHlsPlaylist;
      task.isHls = isHls;

      if (isHls) {
        await _downloadHls(task, request);
      } else if (probe.totalBytes > 0 && probe.acceptRanges) {
        await _downloadParallel(task, request, probe);
      } else {
        await _downloadSequential(task, request);
      }

      task.status = DownloadStatus.completed;
      task.receivedBytes = await File(task.savePath).length();
      _emit(task);
      await MediaScanner.instance.scanFile(task.savePath);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        task.status = _paused.contains(task.id)
            ? DownloadStatus.paused
            : DownloadStatus.canceled;
        task.error = null;
      } else {
        task.status = DownloadStatus.failed;
        task.error = _describeDioError(e);
      }
      await _cleanupParts(task);
      if (task.status == DownloadStatus.canceled) {
        await _deleteIfExists(task.savePath);
      }
    } on DownloaderException catch (e) {
      task.status = DownloadStatus.failed;
      task.error = e.message;
      await _cleanupParts(task);
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.error = '$e';
      await _cleanupParts(task);
    } finally {
      _chunkTokens.remove(task.id);
      _samples.remove(task.id);
      _emit(task);
    }
  }

  Future<ProbeResult> _probe(
    String url,
    Map<String, String>? headers,
  ) async {
    var total = 0;
    var acceptRanges = false;
    var contentType = '';
    try {
      final head = await _dio.head<dynamic>(
        url,
        options: Options(responseType: ResponseType.bytes, headers: headers),
      );
      total = int.tryParse(head.headers.value('content-length') ?? '') ?? 0;
      acceptRanges =
          (head.headers.value('accept-ranges') ?? '').toLowerCase() == 'bytes';
      contentType = head.headers.value('content-type') ?? '';
    } on DioException {
      try {
        final probe = await _dio.get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {...?headers, 'Range': 'bytes=0-0'},
          ),
        );
        if (probe.statusCode == 206) {
          acceptRanges = true;
          total = _parseContentRangeTotal(probe.headers.value('content-range'));
        } else if (probe.statusCode == 200) {
          total =
              int.tryParse(probe.headers.value('content-length') ?? '') ?? 0;
        }
        contentType = probe.headers.value('content-type') ?? '';
      } on DioException {
        // Both probes failed; the sequential path will surface the error.
      }
    }
    final isHls = UrlUtils.looksLikeHls(url) ||
        contentType.contains('mpegurl') ||
        contentType.contains('m3u8');
    return ProbeResult(
      totalBytes: total,
      acceptRanges: acceptRanges,
      isHlsPlaylist: isHls,
    );
  }

  int _parseContentRangeTotal(String? header) {
    if (header == null) return 0;
    final slash = header.lastIndexOf('/');
    if (slash < 0 || slash == header.length - 1) return 0;
    return int.tryParse(header.substring(slash + 1)) ?? 0;
  }

  Future<void> _downloadParallel(
    DownloadTask task,
    DownloadRequest request,
    ProbeResult probe,
  ) async {
    final chunkCount =
        min(max(request.parallelChunks, 1), AppConfig.maxParallelChunks);
    final partPaths = [
      for (var i = 0; i < chunkCount; i++) '${task.savePath}.part$i',
    ];
    final tokens = <CancelToken>[];
    _chunkTokens[task.id] = tokens;

    final bytes = <int>[];
    for (final path in partPaths) {
      bytes.add(await File(path).length());
    }
    _chunkBytes[task.id] = bytes;
    task.receivedBytes = bytes.fold(0, (a, b) => a + b);
    _emit(task);

    final span = (probe.totalBytes / chunkCount).ceil();
    await Future.wait([
      for (var i = 0; i < chunkCount; i++)
        _downloadRange(
          task,
          request,
          tokens,
          partPath: partPaths[i],
          partIndex: i,
          start: i * span,
          end: min((i + 1) * span - 1, probe.totalBytes - 1),
        ),
    ]);
    await _mergeParts(task, partPaths);
  }

  Future<void> _downloadRange(
    DownloadTask task,
    DownloadRequest request,
    List<CancelToken> tokens, {
    required String partPath,
    required int partIndex,
    required int start,
    required int end,
  }) async {
    final token = CancelToken();
    tokens.add(token);
    final file = File(partPath);
    final raf = await file.open(mode: FileMode.append);
    var written = await file.length();
    try {
      while (start + written <= end) {
        final rangeStart = start + written;
        final rangeEnd = min(rangeStart + requestChunkBytes - 1, end);
        final response = await _dio.get<List<int>>(
          request.url,
          options: Options(
            responseType: ResponseType.bytes,
            headers: {...?request.headers, 'Range': 'bytes=$rangeStart-$rangeEnd'},
          ),
          cancelToken: token,
        );
        if (response.statusCode != 206) {
          throw DownloaderException(
            'Server ignored Range requests (HTTP ${response.statusCode}).',
          );
        }
        final data = response.data ?? const <int>[];
        if (data.isEmpty) {
          await Future<void>.delayed(const Duration(milliseconds: 300));
          continue;
        }
        await raf.writeFrom(data);
        written += data.length;
        _chunkBytes[task.id]?[partIndex] = written;
        task.receivedBytes = _chunkBytes[task.id]!.fold(0, (a, b) => a + b);
        _emit(task);
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _mergeParts(
    DownloadTask task,
    List<String> partPaths,
  ) async {
    final out = await File(task.savePath).open(mode: FileMode.write);
    try {
      for (final path in partPaths) {
        final part = File(path);
        if (!await part.exists()) continue;
        await for (final chunk in part.openRead()) {
          await out.writeFrom(chunk);
        }
      }
    } finally {
      await out.close();
    }
    for (final path in partPaths) {
      final part = File(path);
      if (await part.exists()) await part.delete();
    }
  }

  Future<void> _downloadSequential(
    DownloadTask task,
    DownloadRequest request,
  ) async {
    final token = CancelToken();
    _chunkTokens[task.id] = [token];
    final file = File(task.savePath);
    final existing = await file.length();

    if (existing > 0) {
      final resumeResponse = await _dio.get<ResponseBody>(
        request.url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {...?request.headers, 'Range': 'bytes=$existing-'},
        ),
        cancelToken: token,
      );
      if (resumeResponse.statusCode == 206) {
        task.receivedBytes = existing;
        await _pump(task, file, resumeResponse);
        return;
      }
      await file.writeAsBytes(const [], flush: true);
      task.receivedBytes = 0;
    }

    final response = await _dio.get<ResponseBody>(
      request.url,
      options: Options(
        responseType: ResponseType.stream,
        headers: request.headers,
      ),
      cancelToken: token,
    );
    if (response.statusCode != 200) {
      throw DownloaderException(
        'Unexpected HTTP ${response.statusCode} while downloading.',
      );
    }
    final length =
        int.tryParse(response.headers.value('content-length') ?? '');
    if (length != null) task.totalBytes = length;
    await _pump(task, file, response);
  }

  Future<void> _pump(
    DownloadTask task,
    File file,
    Response<ResponseBody> response,
  ) async {
    final raf = await file.open(mode: FileMode.append);
    try {
      await for (final chunk in response.data!.stream) {
        await raf.writeFrom(chunk);
        task.receivedBytes += chunk.length;
        _emit(task);
      }
    } finally {
      await raf.close();
    }
  }

  Future<void> _downloadHls(
    DownloadTask task,
    DownloadRequest request,
  ) async {
    final token = CancelToken();
    _chunkTokens[task.id] = [token];
    await _hlsStitcher.stitch(
      playlistUrl: request.url,
      savePath: task.savePath,
      headers: request.headers,
      cancelToken: token,
      onProgress: (received) {
        task.receivedBytes = received;
        _emit(task);
      },
    );
    task.totalBytes = task.receivedBytes;
  }

  void _emit(DownloadTask task) {
    final now = DateTime.now();
    final previous = _samples[task.id];
    if (previous == null) {
      _samples[task.id] = _SpeedSample(now, task.receivedBytes);
    } else {
      final deltaMs = now.difference(previous.at).inMilliseconds;
      if (deltaMs >= 500) {
        final deltaBytes = task.receivedBytes - previous.bytes;
        task.speedBytesPerSecond = deltaBytes / (deltaMs / 1000);
        _samples[task.id] = _SpeedSample(now, task.receivedBytes);
      }
    }
    _progressController.add(task.toProgress());
  }

  Future<void> _cleanupParts(DownloadTask task) async {
    for (var i = 0; i < (task.totalChunks > 0 ? task.totalChunks : 8); i++) {
      await _deleteIfExists('${task.savePath}.part$i');
    }
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Best-effort cleanup.
      }
    }
  }

  String _describeDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check your network.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.connectionError:
        return 'Could not connect to the server.';
      case DioExceptionType.badResponse:
        return 'Server returned HTTP ${e.response?.statusCode}.';
      default:
        return 'Network error: ${e.message ?? 'unknown'}';
    }
  }

  void dispose() {
    _progressController.close();
  }
}
