/// Static app-wide configuration values.
class AppConfig {
  AppConfig._();

  static const String appName = 'VidKwaii';
  static const String tagline = 'Grab · Stitch · Play';

  /// AWS Lightsail Backend API URL
  static const String defaultApiBaseUrl = 'http://65.0.74.190';

  static const int defaultParallelChunks = 4;
  static const int maxParallelChunks = 8;
}
