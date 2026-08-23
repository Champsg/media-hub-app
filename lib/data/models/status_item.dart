/// A file discovered inside a Storage Access Framework tree
/// (e.g. WhatsApp/Media/.Statuses).
class VaultStatusItem {
  const VaultStatusItem({
    required this.name,
    required this.uri,
    required this.mimeType,
    required this.isDirectory,
    required this.size,
  });

  final String name;
  final String uri;
  final String mimeType;
  final bool isDirectory;
  final int size;

  bool get isImage => mimeType.toLowerCase().startsWith('image/');
  bool get isVideo => mimeType.toLowerCase().startsWith('video/');
  bool get isAudio => mimeType.toLowerCase().startsWith('audio/');
}
