import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  ApiService({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 30),
  }) : _client = client ?? http.Client(),
       _baseUri = baseUri ?? AppConfig.apiBaseUri;

  final http.Client _client;
  final Uri _baseUri;
  final Duration timeout;

  Future<dynamic> get(
    String path, {
    String? token,
    Duration? requestTimeout,
  }) async {
    return _send('GET', path, token: token, requestTimeout: requestTimeout);
  }

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return _send(
      'POST',
      path,
      token: token,
      body: jsonEncode(body),
      contentType: 'application/json',
    );
  }

  Future<dynamic> patchJson(
    String path,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    return _send(
      'PATCH',
      path,
      token: token,
      body: jsonEncode(body),
      contentType: 'application/json',
    );
  }

  Future<dynamic> delete(String path, {String? token}) async {
    return _send('DELETE', path, token: token);
  }

  Future<dynamic> postForm(String path, Map<String, String> fields) async {
    return _send(
      'POST',
      path,
      body: fields,
      contentType: 'application/x-www-form-urlencoded',
      formBody: true,
    );
  }

  Future<dynamic> postMultipart({
    required String path,
    required String fieldName,
    required List<int> bytes,
    required String filename,
    required String token,
    Map<String, String> fields = const {},
  }) async {
    final request = http.MultipartRequest('POST', _resolve(path))
      ..headers['Accept'] = 'application/json'
      ..fields.addAll(fields)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: filename),
      );
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      final decoded = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _errorMessage(decoded, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach ScamShield. Check your network and API address.',
      );
    } on FormatException {
      throw const ApiException(
        'The server returned an invalid response. Please try again later.',
      );
    }
  }

  Future<dynamic> _send(
    String method,
    String path, {
    String? token,
    Object? body,
    String? contentType,
    bool formBody = false,
    Duration? requestTimeout,
  }) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (contentType != null) headers['Content-Type'] = contentType;
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final request = http.Request(method, _resolve(path))
        ..headers.addAll(headers);
      if (formBody && body is Map<String, String>) {
        request.bodyFields = body;
      } else if (body is String) {
        request.body = body;
      }
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(requestTimeout ?? timeout);
      final decoded = _decode(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(
          _errorMessage(decoded, response.statusCode),
          statusCode: response.statusCode,
        );
      }
      return decoded;
    } on TimeoutException {
      throw const ApiException(
        'The server took too long to respond. Please try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Could not reach ScamShield. Check your network and API address.',
      );
    } on FormatException {
      throw const ApiException(
        'The server returned an invalid response. Please try again later.',
      );
    }
  }

  Uri _resolve(String path) {
    final parsed = Uri.parse(path);
    final parsedPath = parsed.path;
    final relative = parsedPath.startsWith('/')
        ? parsedPath.substring(1)
        : parsedPath;
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path
        : '${_baseUri.path}/';
    return _baseUri.replace(
      path: '$basePath$relative',
      query: parsed.hasQuery ? parsed.query : null,
    );
  }

  dynamic _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    final body = utf8.decode(response.bodyBytes);
    try {
      return jsonDecode(body);
    } on FormatException {
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return body;
      }
      throw const FormatException('Invalid JSON response.');
    }
  }

  String _errorMessage(dynamic body, int statusCode) {
    if (statusCode == 401) return 'Invalid email or password.';
    if (statusCode == 403) return 'Access is not available for this account.';
    if (statusCode == 409) {
      return 'An account with this email already exists.';
    }
    if (statusCode >= 500) {
      return 'ScamShield is temporarily unavailable. Please try again.';
    }
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is List) {
        final messages = detail
            .whereType<Map<String, dynamic>>()
            .map((item) => item['msg'])
            .whereType<String>()
            .toList();
        if (messages.isNotEmpty) return messages.join(' ');
      }
    }
    return 'The request could not be completed (HTTP $statusCode).';
  }
}
