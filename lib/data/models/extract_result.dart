import '../../core/utils/formatters.dart';

/// Normalized media format returned by the extractor backend.
class MediaFormat {
  const MediaFormat({
    required this.formatId,
    required this.ext,
    required this.url,
    required this.protocol,
    required this.hasVideo,
    required this.hasAudio,
    required this.isHls,
    this.resolution,
    this.width,
    this.height,
    this.fps,
    this.vcodec,
    this.acodec,
    this.abr,
    this.tbr,
    this.filesize,
    this.formatNote,
    this.qualityLabel,
  });

  final String formatId;
  final String ext;
  final String url;
  final String protocol;
  final String? resolution;
  final int? width;
  final int? height;
  final int? fps;
  final String? vcodec;
  final String? acodec;
  final double? abr;
  final double? tbr;
  final int? filesize;
  final String? formatNote;
  final bool hasVideo;
  final bool hasAudio;
  final bool isHls;
  final String? qualityLabel;

  factory MediaFormat.fromJson(Map<String, dynamic> json) {
    return MediaFormat(
      formatId: json['format_id'] as String? ?? '',
      ext: json['ext'] as String? ?? 'unknown',
      url: json['url'] as String? ?? '',
      protocol: json['protocol'] as String? ?? '',
      resolution: json['resolution'] as String?,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      fps: (json['fps'] as num?)?.toInt(),
      vcodec: json['vcodec'] as String?,
      acodec: json['acodec'] as String?,
      abr: (json['abr'] as num?)?.toDouble(),
      tbr: (json['tbr'] as num?)?.toDouble(),
      filesize: (json['filesize'] as num?)?.toInt(),
      formatNote: json['format_note'] as String?,
      hasVideo: json['has_video'] as bool? ?? false,
      hasAudio: json['has_audio'] as bool? ?? false,
      isHls: json['is_hls'] as bool? ?? false,
      qualityLabel: json['quality_label'] as String?,
    );
  }

  String get sizeLabel => filesize != null ? Formatters.bytes(filesize) : '';

  String get codecLabel {
    final codecs = <String>[
      if (vcodec != null && vcodec != 'none') vcodec!,
      if (acodec != null && acodec != 'none') acodec!,
    ];
    return codecs.join(' + ');
  }

  String get displayLabel {
    final quality = qualityLabel ??
        (height != null ? '${height}p' : formatNote) ??
        formatId;
    final parts = <String>[quality];
    if (isHls) parts.add('HLS');
    if (hasAudio && !hasVideo) parts.add('audio');
    if (sizeLabel != '—') parts.add(sizeLabel);
    return parts.join(' · ');
  }
}

class SubtitleTrack {
  const SubtitleTrack({
    required this.lang,
    required this.name,
    required this.ext,
    required this.url,
  });

  final String lang;
  final String name;
  final String ext;
  final String url;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) => SubtitleTrack(
        lang: json['lang'] as String? ?? '',
        name: json['name'] as String? ?? '',
        ext: json['ext'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

class MediaThumbnail {
  const MediaThumbnail({
    required this.url,
    this.width,
    this.height,
  });

  final String url;
  final int? width;
  final int? height;

  factory MediaThumbnail.fromJson(Map<String, dynamic> json) => MediaThumbnail(
        url: json['url'] as String? ?? '',
        width: (json['width'] as num?)?.toInt(),
        height: (json['height'] as num?)?.toInt(),
      );
}

/// Normalized payload from ``POST /api/v1/extract``.
class ExtractResult {
  const ExtractResult({
    required this.id,
    required this.url,
    required this.title,
    required this.formats,
    required this.thumbnails,
    required this.subtitles,
    this.description,
    this.uploader,
    this.uploadDate,
    this.duration,
    this.durationLabel,
    this.viewCount,
    this.isLive = false,
    this.isHls = false,
    this.isDirect = false,
    this.thumbnail,
    this.suggestedFilename,
    this.recommendedFormatId,
    this.recommendationReason,
    this.webpageUrl,
    this.extractor,
  });

  final String id;
  final String url;
  final String title;
  final String? description;
  final String? uploader;
  final String? uploadDate;
  final int? duration;
  final String? durationLabel;
  final int? viewCount;
  final bool isLive;
  final bool isHls;
  final bool isDirect;
  final String? thumbnail;
  final List<MediaThumbnail> thumbnails;
  final List<MediaFormat> formats;
  final List<SubtitleTrack> subtitles;
  final String? suggestedFilename;
  final String? recommendedFormatId;
  final String? recommendationReason;
  final String? webpageUrl;
  final String? extractor;

  factory ExtractResult.fromJson(Map<String, dynamic> json) {
    return ExtractResult(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled media',
      description: json['description'] as String?,
      uploader: json['uploader'] as String?,
      uploadDate: json['upload_date'] as String?,
      duration: (json['duration'] as num?)?.toInt(),
      durationLabel: json['duration_label'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt(),
      isLive: json['is_live'] as bool? ?? false,
      isHls: json['is_hls'] as bool? ?? false,
      isDirect: json['is_direct'] as bool? ?? false,
      thumbnail: json['thumbnail'] as String?,
      thumbnails: [
        for (final raw in (json['thumbnails'] as List<dynamic>? ?? const []))
          if (raw is Map)
            MediaThumbnail.fromJson(Map<String, dynamic>.from(raw)),
      ],
      formats: [
        for (final raw in (json['formats'] as List<dynamic>? ?? const []))
          if (raw is Map) MediaFormat.fromJson(Map<String, dynamic>.from(raw)),
      ],
      subtitles: [
        for (final raw in (json['subtitles'] as List<dynamic>? ?? const []))
          if (raw is Map) SubtitleTrack.fromJson(Map<String, dynamic>.from(raw)),
      ],
      suggestedFilename: json['suggested_filename'] as String?,
      recommendedFormatId: json['recommended_format_id'] as String?,
      recommendationReason: json['recommendation_reason'] as String?,
      webpageUrl: json['webpage_url'] as String?,
      extractor: json['extractor'] as String?,
    );
  }

  MediaFormat? get bestAudioFormat {
    final audioTracks = formats.where((f) => f.hasAudio && !f.hasVideo).toList();
    if (audioTracks.isNotEmpty) {
      return audioTracks.reduce((a, b) => ((a.abr ?? 0) >= (b.abr ?? 0)) ? a : b);
    }
    final anyAudio = formats.where((f) => f.hasAudio).toList();
    if (anyAudio.isNotEmpty) {
      return anyAudio.reduce((a, b) => ((a.abr ?? 0) >= (b.abr ?? 0)) ? a : b);
    }
    return null;
  }

  MediaFormat? get bestVideoFormat {
    final withAudio = formats.where((f) => f.hasVideo && f.hasAudio).toList();
    if (withAudio.isNotEmpty) {
      return withAudio.reduce((a, b) => ((a.height ?? 0) >= (b.height ?? 0)) ? a : b);
    }
    final videoOnly = formats.where((f) => f.hasVideo).toList();
    if (videoOnly.isNotEmpty) {
      return videoOnly.reduce((a, b) => ((a.height ?? 0) >= (b.height ?? 0)) ? a : b);
    }
    return null;
  }
}

/// A file produced server-side (merged video or extracted audio) that the
/// client can chunk-download like any direct URL.
class MergedFile {
  const MergedFile({
    required this.url,
    required this.filename,
    this.size,
  });

  final String url;
  final String filename;
  final int? size;

  factory MergedFile.fromJson(Map<String, dynamic> json) => MergedFile(
        url: json['url'] as String? ?? '',
        filename: json['filename'] as String? ?? 'media.mp4',
        size: (json['size'] as num?)?.toInt(),
      );
}
