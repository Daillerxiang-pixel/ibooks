import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/app_config.dart';
import 'api_exception.dart';

typedef TokenGetter = String? Function();

/// 對接 Nest `ibooks`：`/api` 前綴下 `books`、`auth`、`chapters` 等。
class IbooksApiClient {
  IbooksApiClient({
    http.Client? httpClient,
    this.tokenGetter,
  }) : _client = httpClient ?? http.Client();

  final http.Client _client;
  final TokenGetter? tokenGetter;

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$p');
  }

  Map<String, String> _headers({bool jsonBody = false}) {
    final h = <String, String>{
      if (jsonBody) 'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final t = tokenGetter?.call();
    if (t != null && t.isNotEmpty) {
      h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  Future<dynamic> get(String path) async {
    final res = await _client.get(_uri(path), headers: _headers());
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(jsonBody: true),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode == 401) {
      throw ApiException(
        '未登入或登入已過期',
        statusCode: 401,
        isUnauthorized: true,
      );
    }
    dynamic decoded;
    try {
      decoded = res.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw ApiException('無效回應（非 JSON）', statusCode: res.statusCode);
    }
    if (res.statusCode >= 500) {
      throw ApiException('伺服器錯誤 ${res.statusCode}', statusCode: res.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('回應格式錯誤', statusCode: res.statusCode);
    }
    final map = decoded;
    final ok = map['success'] == true;
    if (!ok) {
      final err = map['error']?.toString() ?? '請求失敗';
      throw ApiException(err, statusCode: res.statusCode);
    }
    return map['data'];
  }
}
