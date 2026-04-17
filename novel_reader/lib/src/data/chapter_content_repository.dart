import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/chapter_body.dart';
import '../domain/chapter_meta.dart';
import 'crypto/chapter_decryptor.dart';
import 'dto/oss_encrypted_chapter_bundle.dart';

/// 從 OSS 拉取章節 JSON：免費明文 / 付費密文 + 密鑰解密。
class ChapterContentRepository {
  ChapterContentRepository({
    http.Client? httpClient,
    ChapterDecryptor? decryptor,
  })  : _client = httpClient ?? http.Client(),
        _decryptor = decryptor ?? ChapterDecryptor();

  final http.Client _client;
  final ChapterDecryptor _decryptor;

  /// 使用 [ChapterMeta]：明文 OSS 直接解析；加密 OSS（含免費測試章）需 [contentKeyBase64] 解密。
  Future<ChapterBody> loadBody(ChapterMeta meta) async {
    if (meta.contentOssUrls.isEmpty) {
      throw StateError('No OSS URLs for chapter ${meta.id}');
    }
    final url = meta.contentOssUrls.first;
    final raw = await _fetchString(url);

    if (!meta.isEncrypted) {
      return _parsePlainJson(raw);
    }

    final key = meta.contentKeyBase64;
    if (key == null || key.isEmpty) {
      throw StateError('Encrypted chapter ${meta.id} requires contentKeyBase64');
    }

    final bundle = OssEncryptedChapterBundle.parse(raw);
    final map = _decryptor.decryptToChapterJson(bundle, key);
    return ChapterBody.fromJson(map);
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
