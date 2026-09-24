import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../core/config/app_config.dart';
import '../core/config/remote_config.dart';

/// Loads and persists runtime settings (backend URL, chunk count).
///
/// The backend address is refreshed from [RemoteConfig] so it can be moved
/// between hosts without releasing a new app build. Startup never waits on the
/// network: the last known-good address is used first, then the remote value
/// is applied once it has been fetched *and* verified as reachable.
class AppConfigController extends ChangeNotifier {
  AppConfigController(this.config);

  final ApiConfig config;
  bool loaded = false;
  Timer? _refreshTimer;

  /// How often the remote config is re-checked while the app is running.
  static const Duration refreshInterval = Duration(minutes: 30);

  Future<void> load() async {
    // 1. Start with the last known-good address so the UI never blocks.
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRemote = _usable(prefs.getString('remote_api_base_url'));
      final saved = _usable(prefs.getString('api_base_url'));
      config.baseUrl =
          cachedRemote ?? saved ?? AppConfig.defaultApiBaseUrl;
      config.parallelChunks =
          prefs.getInt('parallel_chunks') ?? AppConfig.defaultParallelChunks;
    } catch (_) {
      // Keep the built-in default if prefs are unavailable.
    } finally {
      loaded = true;
      notifyListeners();
    }

    // 2. Then ask the remote config, in the background.
    await refreshRemote();
    _refreshTimer ??=
        Timer.periodic(refreshInterval, (_) => refreshRemote());
  }

  /// Fetches the remotely configured backend address and switches to it only
  /// when it is reachable. Anything else leaves the current address untouched.
  Future<void> refreshRemote() async {
    final candidate = await RemoteConfig.fetchApiBaseUrl();
    if (candidate == null || candidate == config.baseUrl) return;

    if (!await RemoteConfig.isHealthy(candidate)) {
      debugPrint(
        '[AppConfig] Remote backend $candidate is unreachable — keeping '
        '${config.baseUrl}',
      );
      return;
    }

    debugPrint('[AppConfig] Switched backend to $candidate');
    config.baseUrl = candidate;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('remote_api_base_url', candidate);
    } catch (_) {
      // Non-fatal: the switch already applies for this session.
    }
  }

  Future<void> setBaseUrl(String value) async {
    final trimmed = RemoteConfig.trimTrailingSlash(value.trim());
    if (!RemoteConfig.isUsableUrl(trimmed)) return;
    config.baseUrl = trimmed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', trimmed);
  }

  Future<void> setParallelChunks(int value) async {
    config.parallelChunks =
        value.clamp(1, AppConfig.maxParallelChunks).toInt();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('parallel_chunks', config.parallelChunks);
  }

  String? _usable(String? value) {
    if (value == null) return null;
    final trimmed = RemoteConfig.trimTrailingSlash(value.trim());
    return RemoteConfig.isUsableUrl(trimmed) ? trimmed : null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
