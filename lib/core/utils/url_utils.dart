/// URL heuristics used by clipboard detection, the sniffer and downloader.
class UrlUtils {
  UrlUtils._();

  static final RegExp _directMedia = RegExp(
    r'\.(mp4|m3u8|m4a|mp3|webm|mov|mkv|ts|aac|ogg|opus|flac|wav)(\?[^#]*)?(#.*)?$',
    caseSensitive: false,
  );

  static bool isInstagramUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    if (uri == null || uri.host.isEmpty) return false;
    final host = uri.host.toLowerCase();
    return host == 'instagram.com' ||
        host.endsWith('.instagram.com') ||
        host == 'instagr.am' ||
        host.endsWith('.instagr.am') ||
        host == 'cdninstagram.com';
  }

  static bool isLikelyMediaUrl(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    return isInstagramUrl(trimmed);
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
