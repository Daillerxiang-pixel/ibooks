import 'dart:convert';
import 'dart:io' show SocketException;

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
    final res = await _send(() => _client.get(_uri(path), headers: _headers()));
    return _decode(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _send(
      () => _client.post(
        _uri(path),
        headers: _headers(jsonBody: true),
        body: jsonEncode(body),
      ),
    );
    return _decode(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _send(() => _client.delete(_uri(path), headers: _headers()));
    return _decode(res);
  }

  /// 將 DNS/斷網等轉為可讀提示（errno 7 / Failed host lookup = 本機未解析域名，非後端 HTTP 錯）
  Future<http.Response> _send(Future<http.Response> Function() fn) async {
    try {
      return await fn();
    } on SocketException catch (e) {
      throw ApiException(_networkUserMessage(e.message, e));
    } on http.ClientException catch (e) {
      throw ApiException(_networkUserMessage(e.message, e));
    }
  }

  static String _networkUserMessage(String message, Object err) {
    final m = message.toLowerCase();
    final all = err.toString().toLowerCase();
    if (m.contains('failed host lookup') ||
        m.contains('no address associated') ||
        all.contains('failed host lookup') ||
        all.contains('no address associated')) {
      return '無法解析域名（DNS），手機尚未連上 API 地址。請檢查：①網路是否可用 ②換 Wi‑Fi / 移動數據 ③系統 DNS（可試 8.8.8.8）④用瀏覽器打開 https://book.kanashortplay.com/api/books 對照。';
    }
    return '網路連線失敗：$message';
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
