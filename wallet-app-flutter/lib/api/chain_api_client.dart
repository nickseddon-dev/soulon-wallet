import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_error_mapper.dart';

class ChainApiClient {
  ChainApiClient({
    required this.baseUrl,
    required this.timeout,
    this.maxRetries = 1,
    this.retryBackoff = const Duration(milliseconds: 500),
  }) : _httpClient = HttpClient();

  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final Duration retryBackoff;
  final HttpClient _httpClient;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    return _executeWithRetry(() async {
      final uri = _buildUri(path, query: query);
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      final responseText = await utf8.decoder.bind(response).join();
      return _parseResponse(response.statusCode, responseText);
    });
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    return _executeWithRetry(() async {
      final uri = _buildUri(path, query: query);
      final request = await _httpClient.postUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(body ?? <String, dynamic>{}));
      final response = await request.close().timeout(timeout);
      final responseText = await utf8.decoder.bind(response).join();
      return _parseResponse(response.statusCode, responseText);
    });
  }

  void close() {
    _httpClient.close();
  }

  Future<Map<String, dynamic>> _executeWithRetry(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await action();
      } on ApiClientException catch (e) {
        final retryable = e.statusCode != null && _isRetryableStatus(e.statusCode!);
        if (!retryable || attempt >= maxRetries) {
          rethrow;
        }
        await Future<void>.delayed(retryBackoff * (attempt + 1));
      } on TimeoutException {
        if (attempt >= maxRetries) {
          throw const ApiClientException(kind: ApiErrorKind.timeout);
        }
        await Future<void>.delayed(retryBackoff * (attempt + 1));
      } on SocketException {
        if (attempt >= maxRetries) {
          throw const ApiClientException(kind: ApiErrorKind.network);
        }
        await Future<void>.delayed(retryBackoff * (attempt + 1));
      } on HttpException {
        if (attempt >= maxRetries) {
          throw const ApiClientException(kind: ApiErrorKind.network);
        }
        await Future<void>.delayed(retryBackoff * (attempt + 1));
      } on FormatException {
        rethrow;
      } catch (_) {
        if (attempt >= maxRetries) {
          throw const ApiClientException(kind: ApiErrorKind.unknown);
        }
        await Future<void>.delayed(retryBackoff * (attempt + 1));
      }
    }
    throw const ApiClientException(kind: ApiErrorKind.unknown);
  }

  bool _isRetryableStatus(int statusCode) {
    return statusCode == 429 || statusCode >= 500;
  }

  Uri _buildUri(
    String path, {
    Map<String, String>? query,
  }) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }
    return uri.replace(queryParameters: query);
  }

  Map<String, dynamic> _parseResponse(int statusCode, String responseText) {
    final body = _decodeJsonObject(responseText);
    if (statusCode >= 200 && statusCode < 300) {
      return body;
    }
    final errorCode = body['code']?.toString();
    final errorMessage = body['message']?.toString();
    throw ApiClientException(
      kind: _mapErrorKind(statusCode),
      statusCode: statusCode,
      code: errorCode,
      message: errorMessage,
    );
  }

  Map<String, dynamic> _decodeJsonObject(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw const FormatException('响应格式错误，预期 JSON 对象');
  }

  ApiErrorKind _mapErrorKind(int statusCode) {
    if (statusCode == 400) {
      return ApiErrorKind.validation;
    }
    if (statusCode == 401) {
      return ApiErrorKind.unauthorized;
    }
    if (statusCode == 403) {
      return ApiErrorKind.forbidden;
    }
    if (statusCode == 404) {
      return ApiErrorKind.notFound;
    }
    if (statusCode >= 500) {
      return ApiErrorKind.network;
    }
    return ApiErrorKind.unknown;
  }
}
