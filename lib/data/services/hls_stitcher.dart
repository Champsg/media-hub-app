import 'dart:io';

import 'package:dio/dio.dart';

import '../models/download_task.dart';

class _ResolvedPlaylist {
  const _ResolvedPlaylist({required this.content, required this.baseUri});

  final String content;
  final Uri baseUri;
}

/// Downloads every segment of an HLS playlist and concatenates it into a
/// single local file. Handles master playlists by picking the highest
/// bandwidth variant; reports progress via a callback.
class HlsStitcher {
  HlsStitcher({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 90),
                followRedirects: true,
              ),
            );

  final Dio _dio;

  Future<void> stitch({
    required String playlistUrl,
    required String savePath,
    Map<String, String>? headers,
    required CancelToken cancelToken,
    required void Function(int received) onProgress,
  }) async {
    final resolved =
        await _resolvePlaylist(playlistUrl, headers, cancelToken);
    final segments = <String>[];
    for (final line in resolved.content.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      segments.add(resolved.baseUri.resolve(trimmed).toString());
    }
    if (segments.isEmpty) {
      throw DownloaderException('Playlist contains no media segments.');
    }

    final out = await File(savePath).open(mode: FileMode.write);
    var received = 0;
    try {
      for (var i = 0; i < segments.length; i++) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: segments[i]),
            type: DioExceptionType.cancel,
            error: 'Download cancelled',
          );
        }
        final response = await _dio.get<List<int>>(
          segments[i],
          options: Options(
            responseType: ResponseType.bytes,
            headers: headers,
          ),
          cancelToken: cancelToken,
        );
        final data = response.data ?? const <int>[];
        if (data.isNotEmpty) {
          await out.writeFrom(data);
          received += data.length;
          onProgress(received);
        }
      }
    } finally {
      await out.close();
    }
  }

  Future<_ResolvedPlaylist> _resolvePlaylist(
    String url,
    Map<String, String>? headers,
    CancelToken cancelToken,
  ) async {
    final response = await _dio.get<String>(
      url,
      options: Options(
        responseType: ResponseType.plain,
        headers: headers,
      ),
      cancelToken: cancelToken,
    );
    final content = response.data ?? '';
    final base = Uri.parse(url);

    if (content.contains('#EXT-X-KEY')) {
      throw DownloaderException(
        'Encrypted (AES-128) HLS streams are not supported yet.',
      );
    }
    if (content.contains('#EXTINF')) {
      return _ResolvedPlaylist(content: content, baseUri: base);
    }
    if (!content.contains('#EXT-X-STREAM-INF')) {
      throw DownloaderException('URL did not return a valid HLS playlist.');
    }

    final variantPattern = RegExp(r'#EXT-X-STREAM-INF:([^\n]*)\n([^\n]+)');
    var bestUrl = '';
    var bestBandwidth = -1;
    for (final match in variantPattern.allMatches(content)) {
      final attrs = match.group(1) ?? '';
      final bandwidth = int.tryParse(
            RegExp(r'BANDWIDTH=(\d+)').firstMatch(attrs)?.group(1) ?? '',
          ) ??
          0;
      final uri = match.group(2)?.trim() ?? '';
      if (bandwidth > bestBandwidth) {
        bestBandwidth = bandwidth;
        bestUrl = base.resolve(uri).toString();
      }
    }
    if (bestUrl.isEmpty) {
      throw DownloaderException(
        'Could not locate a media playlist inside the master playlist.',
      );
    }
    return _resolvePlaylist(bestUrl, headers, cancelToken);
  }
}
