/// Human-friendly formatting helpers.
class Formatters {
  Formatters._();

  static String bytes(int? bytes) {
    if (bytes == null || bytes < 0) return '—';
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = -1;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return unit < 0 ? '$bytes B' : '${value.toStringAsFixed(1)} ${units[unit]}';
  }

  static String speed(double bytesPerSecond) {
    return '${bytes(bytesPerSecond.round())}/s';
  }

  static String percent(double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    return '${(clamped * 100).toStringAsFixed(0)}%';
  }

  static String duration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0:00';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  static String compactCount(int? count) {
    if (count == null || count < 0) return '';
    if (count >= 1000000000) {
      return '${(count / 1000000000).toStringAsFixed(1)}B';
    }
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}
