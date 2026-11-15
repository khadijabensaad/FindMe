import 'dart:async';
import 'dart:convert';

import 'package:find_me/core/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

/// Small JSON client shared by every FINDME AI service.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  static const _timeout = Duration(seconds: 25);

  Future<String?> token() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userToken');
  }

  /// Current user id decoded from the JWT (null for guests).
  Future<String?> userId() async {
    final t = await token();
    if (t == null || t.isEmpty) return null;
    try {
      final decoded = JwtDecoder.decode(t);
      return decoded['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _headers() async {
    final t = await token();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  Uri uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v == null) return;
      if (v is List) {
        if (v.isNotEmpty) q[k] = v.join(',');
      } else if (v.toString().isNotEmpty) {
        q[k] = v.toString();
      }
    });
    return Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  dynamic _decode(http.Response r) {
    final body = r.body.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = body is Map ? (body['message'] ?? body['error'] ?? 'Request failed').toString() : 'Request failed (${r.statusCode})';
    throw ApiException(r.statusCode, msg);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final r = await http.get(uri(path, query), headers: await _headers()).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(uri(path), headers: await _headers(), body: jsonEncode(body)).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final r = await http.put(uri(path), headers: await _headers(), body: jsonEncode(body)).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(uri(path), headers: await _headers(), body: jsonEncode(body)).timeout(_timeout);
    return _decode(r);
  }

  Future<dynamic> delete(String path) async {
    final r = await http.delete(uri(path), headers: await _headers()).timeout(_timeout);
    return _decode(r);
  }

  /// Multipart upload from bytes: works on Android, iOS AND web (no dart:io File).
  Future<dynamic> uploadBytes(
    String path, {
    required List<int> bytes,
    required String filename,
    String field = 'image',
    String method = 'POST',
    Map<String, String> fields = const {},
    Map<String, dynamic>? query,
  }) async {
    final req = http.MultipartRequest(method, uri(path, query));
    final t = await token();
    if (t != null && t.isNotEmpty) req.headers['Authorization'] = 'Bearer $t';
    req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }

  /// Multipart form without a file (e.g. profile name only).
  Future<dynamic> multipartFields(String path, Map<String, String> fields, {String method = 'PUT'}) async {
    final req = http.MultipartRequest(method, uri(path));
    final t = await token();
    if (t != null && t.isNotEmpty) req.headers['Authorization'] = 'Bearer $t';
    req.fields.addAll(fields);
    final streamed = await req.send().timeout(const Duration(seconds: 30));
    return _decode(await http.Response.fromStream(streamed));
  }

  Future<dynamic> uploadImage(String path, String filePath, {String field = 'image', Map<String, String>? query}) async {
    final req = http.MultipartRequest('POST', uri(path, query));
    final t = await token();
    if (t != null && t.isNotEmpty) req.headers['Authorization'] = 'Bearer $t';
    req.files.add(await http.MultipartFile.fromPath(field, filePath));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final r = await http.Response.fromStream(streamed);
    return _decode(r);
  }
}
