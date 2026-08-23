import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';
import '../core/config/app_config.dart';

/// Loads and persists runtime settings (backend URL, chunk count).
class AppConfigController extends ChangeNotifier {
  AppConfigController(this.config);

  final ApiConfig config;
  bool loaded = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      config.baseUrl =
          prefs.getString('api_base_url') ?? AppConfig.defaultApiBaseUrl;
      config.parallelChunks =
          prefs.getInt('parallel_chunks') ?? AppConfig.defaultParallelChunks;
    } catch (_) {
      // Keep defaults if prefs are unavailable.
    } finally {
      loaded = true;
      notifyListeners();
    }
  }

  Future<void> setBaseUrl(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
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
}
