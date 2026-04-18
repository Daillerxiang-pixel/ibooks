import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/chapter_body.dart';
import '../domain/chapter_meta.dart';
import 'crypto/chapter_decryptor.dart';
import 'dto/oss_encrypted_chapter_bundle.dart';

/// 從 OSS 拉取章節 JSON：免費明文 / 付費密文 + 密鑰解密。
/// 內置 LRU 記憶體快取（最多 8 章），相同章節不重複下載。
class ChapterContentRepository {
  ChapterContentRepository({
    http.Client? httpClient,
    ChapterDecryptor? decryptor,
    int cacheSize = 8,
  })  : _client = httpClient ?? http.Client(),
        _decryptor = decryptor ?? ChapterDecryptor(),
        _cacheSize = cacheSize;

  final http.Client _client;
  final ChapterDecryptor _decryptor;
  final int _cacheSize;

  // LinkedHashMap 保持插入順序，用於 LRU 淘汰
  final LinkedHashMap<String, ChapterBody> _cache = LinkedHashMap();

  /// 使用 [ChapterMeta]：明文 OSS 直接解析；加密 OSS（含免費測試章）需 [contentKeyBase64] 解密。
  Future<ChapterBody> loadBody(ChapterMeta meta) async {
    final cacheKey = meta.id;
    if (_cache.containsKey(cacheKey)) {
      // LRU：移到尾部
      final cached = _cache.remove(cacheKey)!;
      _cache[cacheKey] = cached;
      return cached;
    }

    if (meta.contentOssUrls.isEmpty) {
      throw StateError('No OSS URLs for chapter ${meta.id}');
    }
    final url = meta.contentOssUrls.first;
    final raw = await _fetchString(url);

    ChapterBody body;
    if (!meta.isEncrypted) {
      body = _parsePlainJson(raw);
    } else {
      final key = meta.contentKeyBase64;
      if (key == null || key.isEmpty) {
        throw StateError('Encrypted chapter ${meta.id} requires contentKeyBase64');
      }
      final bundle = OssEncryptedChapterBundle.parse(raw);
      final map = _decryptor.decryptToChapterJson(bundle, key);
      body = ChapterBody.fromJson(map);
    }

    // 寫入快取並維持大小
    _cache[cacheKey] = body;
    if (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
    return body;
  }

  /// 預載入（fire-and-forget），不拋出錯誤
  void prefetch(ChapterMeta meta) {
    if (_cache.containsKey(meta.id)) return;
    loadBody(meta).then((_) {}).catchError((_) {});
  }

  Future<String> _fetchString(String url) async {
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw ChapterContentException('GET $url failed: ${res.statusCode}');
    }
    return utf8.decode(res.bodyBytes);
  }

  ChapterBody _parsePlainJson(String raw) {
    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic>) {
      throw FormatException('Plain chapter JSON must be an object');
    }
    return ChapterBody.fromJson(map);
  }
}

class ChapterContentException implements Exception {
  ChapterContentException(this.message);
  final String message;
  @override
  String toString() => message;
}
