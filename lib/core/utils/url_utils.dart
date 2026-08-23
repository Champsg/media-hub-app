/// URL heuristics used by clipboard detection, the sniffer and downloader.
class UrlUtils {
  UrlUtils._();

  static final RegExp _directMedia = RegExp(
    r'\.(mp4|m3u8|m4a|mp3|webm|mov|mkv|ts|aac|ogg|opus|flac|wav)(\?[^#]*)?(#.*)?$',
    caseSensitive: false,
  );

  static const List<String> _mediaHosts = [
    'youtube.com',
    'youtu.be',
    'tiktok.com',
    'instagram.com',
    'twitter.com',
    'x.com',
    'facebook.com',
    'fb.watch',
    'vimeo.com',
    'reddit.com',
    'twitch.tv',
    'soundcloud.com',
    'dailymotion.com',
    'pinterest.com',
    'tumblr.com',
    'bilibili.com',
    'streamable.com',
  ];

  static bool isLikelyMediaUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (isDirectMediaUrl(trimmed)) return true;
    if (!trimmed.toLowerCase().startsWith('http')) return false;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return _mediaHosts.any((h) => host == h || host.endsWith('.$h'));
  }

  static bool isDirectMediaUrl(String text) {
    return _directMedia.hasMatch(text.trim());
  }

  static bool looksLikeHls(String text) {
    return text.toLowerCase().contains('.m3u8');
  }

  static String displayHost(String url) {
    final uri = Uri.tryParse(url.trim());
    return uri?.host.isNotEmpty == true ? uri!.host : url;
  }
}
