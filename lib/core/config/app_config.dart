/// Static app-wide configuration values.
class AppConfig {
  AppConfig._();

  static const String appName = 'Media Hub';
  static const String tagline = 'Grab Â· Stitch Â· Play';

  /// Live Render Cloud API URL
  static const String defaultApiBaseUrl = 'https://media-hub-backend-utan.onrender.com';

  static const int defaultParallelChunks = 4;
  static const int maxParallelChunks = 8;
}