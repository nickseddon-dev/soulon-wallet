import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'api_error_mapper.dart';

class ChainApiClient {
  ChainApiClient({
    required this.baseUrl,
    required this.timeout,
  }) : _httpClient = HttpClient();

  final String baseUrl;
  final Duration timeout;
  final HttpClient _httpClient;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final uri = _buildUri(path, query: query);
    try {
      final request = await _httpClient.getUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(timeout);
      final responseText = await utf8.decoder.bind(response).join();
      return _parseResponse(response.statusCode, responseText);
    } on TimeoutException {
      throw const ApiClientException(kind: ApiErrorKind.timeout);
    } on SocketException {
      throw const ApiClientException(kind: ApiErrorKind.network);
    } on HttpException {
      throw const ApiClientException(kind: ApiErrorKind.network);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const ApiClientException(kind: ApiErrorKind.unknown);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path, query: query);
    try {
      final request = await _httpClient.postUrl(uri).timeout(timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(body ?? <String, dynamic>{}));
      final response = await request.close().timeout(timeout);
      final responseText = await utf8.decoder.bind(response).join();
      return _parseResponse(response.statusCode, responseText);
    } on TimeoutException {
      throw const ApiClientException(kind: ApiErrorKind.timeout);
    } on SocketException {
      throw const ApiClientException(kind: ApiErrorKind.network);
    } on HttpException {
      throw const ApiClientException(kind: ApiErrorKind.network);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const ApiClientException(kind: ApiErrorKind.unknown);
    }
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
