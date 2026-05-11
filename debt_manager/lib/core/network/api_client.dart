import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_endpoints.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const String _tokenKey = 'auth_token';
  static const _timeout = Duration(seconds: 60);

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, String>> _headers({bool auth = false}) async {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Uri _uri(String path) => Uri.parse('${ApiEndpoints.baseUrl}$path');

  Map<String, dynamic> _parse(http.Response res) {
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300) return body;
      throw ApiException(body['message'] ?? 'Request failed', res.statusCode);
    } on FormatException {
      throw ApiException('Invalid server response');
    }
  }

  Future<http.Response> _withRetry(Future<http.Response> Function() fn) async {
    try {
      return await fn();
    } on TimeoutException {
      await Future.delayed(const Duration(seconds: 4));
      try {
        return await fn();
      } on TimeoutException {
        throw ApiException('Server is starting up, please try again.');
      }
    }
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    try {
      final h = await _headers(auth: auth);
      final res = await _withRetry(
          () => http.get(_uri(path), headers: h).timeout(_timeout));
      return _parse(res);
    } on SocketException {
      throw ApiException('No internet connection.');
    }
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body,
      {bool auth = false}) async {
    try {
      final h = await _headers(auth: auth);
      final res = await _withRetry(() => http
          .post(_uri(path), headers: h, body: jsonEncode(body))
          .timeout(_timeout));
      return _parse(res);
    } on SocketException {
      throw ApiException('No internet connection.');
    }
  }

  Future<Map<String, dynamic>> put(
      String path, Map<String, dynamic> body) async {
    try {
      final h = await _headers(auth: true);
      final res = await _withRetry(() => http
          .put(_uri(path), headers: h, body: jsonEncode(body))
          .timeout(_timeout));
      return _parse(res);
    } on SocketException {
      throw ApiException('No internet connection.');
    }
  }

  Future<Map<String, dynamic>> patch(String path) async {
    try {
      final h = await _headers(auth: true);
      final res = await _withRetry(
          () => http.patch(_uri(path), headers: h).timeout(_timeout));
      return _parse(res);
    } on SocketException {
      throw ApiException('No internet connection.');
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final h = await _headers(auth: true);
      final res = await _withRetry(
          () => http.delete(_uri(path), headers: h).timeout(_timeout));
      return _parse(res);
    } on SocketException {
      throw ApiException('No internet connection.');
    }
  }
}
