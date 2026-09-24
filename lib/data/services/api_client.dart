import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../models/extract_result.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Typed client for the Media Hub extractor backend.
class ApiClient {
  ApiClient(this._config) {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  final ApiConfig _config;
  late final Dio _dio;

  /// Resolved per request, so a backend address changed at runtime (see
  /// [AppConfigController.refreshRemote]) takes effect immediately instead of
  /// only after a restart.
  String _url(String path) {
    final base = _config.baseUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$base${path.startsWith('/') ? path : '/$path'}';
  }

  Future<ExtractResult> extract(
    String url, {
    bool audioOnly = false,
    String? preferredQuality,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _url('/api/v1/extract'),
        data: {
          'url': url,
          'audio_only': audioOnly,
          'preferred_quality': preferredQuality,
        },
      );
      final body = response.data;
      if (body == null || body['ok'] != true || body['data'] == null) {
        throw ApiException('Unexpected response from the server.');
      }
      return ExtractResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_describeDioError(e));
    }
  }

  Future<bool> health() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_url('/health'));
      return response.data?['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  /// Asks the backend to download and merge video+audio into a single .mp4
  /// (server-side FFmpeg), returning a URL the client can chunk-download.
  Future<MergedFile> mergeMedia(
    String url, {
    String? quality,
  }) async {
    return _produceFile(
      '/api/v1/merge',
      {'url': url, 'quality': quality},
    );
  }

  /// Asks the backend to extract the best audio track as .m4a / .mp3.
  Future<MergedFile> extractAudio(
    String url, {
    String format = 'm4a',
  }) async {
    return _produceFile(
      '/api/v1/audio',
      {'url': url, 'format': format},
    );
  }

  Future<MergedFile> _produceFile(
    String path,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _url(path),
        data: data,
        options: Options(
          receiveTimeout: const Duration(minutes: 15),
        ),
      );
      final body = response.data;
      if (body == null || body['ok'] != true || body['file'] == null) {
        throw ApiException('Unexpected response from the server.');
      }
      final file =
          MergedFile.fromJson(body['file'] as Map<String, dynamic>);
      return MergedFile(
        url: _absolute(file.url),
        filename: file.filename,
        size: file.size,
      );
    } on DioException catch (e) {
      throw ApiException(_describeDioError(e));
    }
  }

  String _absolute(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return _url(path);
  }

  String _describeDioError(DioException e) {
    if (e.response != null) {
      final detail = e.response?.data;
      if (detail is Map && detail['error'] is Map) {
        final error = detail['error'] as Map;
        final message = error['message'] as String?;
        final suggestion = error['suggestion'] as String?;
        if (message != null) {
          return suggestion == null ? message : '$message\n$suggestion';
        }
      }
      return 'Server error (HTTP ${e.response?.statusCode}).';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check your network and try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.connectionError:
        return 'Could not reach the download service. Check your network and try again.';
      default:
        return 'Network error: ${e.message ?? 'unknown'}';
    }
  }
}
