import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Error yang dilempar ketika request ke backend gagal.
///
/// [message] sudah ramah pengguna sehingga bisa langsung ditampilkan di UI.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;

  /// `null` bila request tidak sampai ke server (offline / timeout).
  final int? statusCode;

  @override
  String toString() => message;
}

/// HTTP client tipis untuk REST API Smart Kantin Kampus.
///
/// Mengembalikan body JSON yang sudah di-decode (Map/List/null).
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  static final ApiClient instance = ApiClient();

  final http.Client _client;
  final String _baseUrl;

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<dynamic> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, Object?>? query,
  }) =>
      _send('PUT', path, body: body, query: query);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path, {Map<String, Object?>? query}) =>
      _send('DELETE', path, query: query);

  Uri _uri(String path, Map<String, Object?>? query) {
    final params = <String, String>{
      for (final entry in (query ?? const {}).entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    final uri = Uri.parse('$_baseUrl/$path');
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final request = http.Request(method, _uri(path, query))
      ..headers.addAll(_headers);
    if (body != null) request.body = jsonEncode(body);

    final http.Response response;
    try {
      final streamed = await _client.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(
        'Server tidak merespons. Periksa koneksi internet lalu coba lagi.',
      );
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }

    final decoded = _decode(response.body);
    final status = response.statusCode;
    if (status >= 200 && status < 300) return decoded;

    throw ApiException(
      _messageFrom(decoded) ?? 'Permintaan ke server gagal (kode $status).',
      statusCode: status,
    );
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }

  String? _messageFrom(dynamic decoded) {
    if (decoded is! Map) return null;
    final message = decoded['message'];
    return message is String && message.isNotEmpty ? message : null;
  }
}
