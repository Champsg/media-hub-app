import 'dart:io';

enum MediaKind { video, audio, image, other }

class LibraryItem {
  const LibraryItem({
    required this.path,
    required this.name,
    required this.size,
    required this.modified,
    required this.kind,
  });

  final String path;
  final String name;
  final int size;
  final DateTime modified;
  final MediaKind kind;

  factory LibraryItem.fromFile(File file) {
    final lower = file.path.toLowerCase();
    final kind = _video.hasMatch(lower)
        ? MediaKind.video
        : _audio.hasMatch(lower)
            ? MediaKind.audio
            : _image.hasMatch(lower)
                ? MediaKind.image
                : MediaKind.other;
    return LibraryItem(
      path: file.path,
      name: file.uri.pathSegments.isEmpty
          ? file.path
          : file.uri.pathSegments.last,
      size: file.lengthSync(),
      modified: file.lastModifiedSync(),
      kind: kind,
    );
  }

  static final RegExp _video =
      RegExp(r'\.(mp4|webm|mkv|mov|avi|ts|m4v|3gp)$', caseSensitive: false);
  static final RegExp _audio =
      RegExp(r'\.(mp3|m4a|aac|wav|flac|ogg|opus|amr)$', caseSensitive: false);
  static final RegExp _image =
      RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)$', caseSensitive: false);
}
