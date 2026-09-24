/// Download domain models shared by the downloader, stitcher and UI.

enum DownloadStatus { queued, running, merging, paused, completed, failed, canceled }

class DownloadProgress {
  const DownloadProgress({
    required this.taskId,
    required this.totalBytes,
    required this.receivedBytes,
    required this.speedBytesPerSecond,
    required this.status,
  });

  final String taskId;
  final int totalBytes;
  final int receivedBytes;
  final double speedBytesPerSecond;
  final DownloadStatus status;

  double get fraction =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  Duration? get eta {
    if (speedBytesPerSecond <= 0 || totalBytes <= 0) return null;
    final remaining =
        ((totalBytes - receivedBytes) / speedBytesPerSecond).round();
    return Duration(seconds: remaining < 0 ? 0 : remaining);
  }
}

class DownloadRequest {
  const DownloadRequest({
    required this.url,
    required this.fileName,
    required this.saveDirectory,
    this.audioUrl,
    this.audioHeaders,
    this.parallelChunks = 4,
    this.isHls = false,
    this.headers,
  });

  final String url;
  final String? audioUrl;
  final Map<String, String>? audioHeaders;
  final String fileName;
  final String saveDirectory;
  final int parallelChunks;
  final bool isHls;
  final Map<String, String>? headers;

  bool get isDualStream => audioUrl != null && audioUrl!.isNotEmpty;
}

class DownloadTask {
  DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.savePath,
    required this.isHls,
    required this.totalChunks,
    this.audioUrl,
  });

  final String id;
  final String url;
  final String? audioUrl;
  final String fileName;
  final String savePath;
  bool isHls;
  final int totalChunks;

  bool get isDualStream => audioUrl != null && audioUrl!.isNotEmpty;

  DownloadStatus status = DownloadStatus.queued;
  int totalBytes = 0;
  int receivedBytes = 0;
  double speedBytesPerSecond = 0;
  String? error;
  final DateTime createdAt = DateTime.now();

  DownloadProgress toProgress() => DownloadProgress(
        taskId: id,
        totalBytes: totalBytes,
        receivedBytes: receivedBytes,
        speedBytesPerSecond: speedBytesPerSecond,
        status: status,
      );
}

/// A media URL observed by the in-app browser sniffer.
class SniffedMedia {
  SniffedMedia({
    required this.url,
    required this.type,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  final String url;
  final String type;
  final DateTime detectedAt;

  factory SniffedMedia.fromJson(Map<String, dynamic> json) => SniffedMedia(
        url: json['url'] as String? ?? '',
        type: json['type'] as String? ?? 'media',
      );
}

class DownloaderException implements Exception {
  DownloaderException(this.message);

  final String message;

  @override
  String toString() => message;
}
