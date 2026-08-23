import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import '../models/extract_result.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Typed client for the Media Hub extractor backend.
class ApiClient {
  ApiClient(this._config) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _config.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 120),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  final ApiConfig _config;
  late final Dio _dio;

  Future<ExtractResult> extract(
    String url, {
    bool audioOnly = false,
    String? preferredQuality,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/v1/extract',
        data: {
          'url': url,
          'audio_only': audioOnly,
          'preferred_quality': preferredQuality,
        },
      );
      final body = response.data;
      if (body == null || body['ok'] != true || body['data'] == null) {
        throw ApiException('Unexpected response from the server.');
      }
      return ExtractResult.fromJson(body['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(_describeDioError(e));
    }
  }

  Future<bool> health() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      return response.data?['status'] == 'ok';
    } on DioException {
      return false;
    }
  }

  String _describeDioError(DioException e) {
    if (e.response != null) {
      final detail = e.response?.data;
      if (detail is Map && detail['error'] is Map) {
        final error = detail['error'] as Map;
        final message = error['message'] as String?;
        final suggestion = error['suggestion'] as String?;
        if (message != null) {
          return suggestion == null ? message : '$message\n$suggestion';
        }
      }
      return 'Server error (HTTP ${e.response?.statusCode}).';
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timed out. Check the server URL in Settings.';
      case DioExceptionType.receiveTimeout:
        return 'Server took too long to respond.';
      case DioExceptionType.connectionError:
        return 'Could not reach the backend server. Check your network and the URL in Settings.';
      default:
        return 'Network error: ${e.message ?? 'unknown'}';
    }
  }
}
