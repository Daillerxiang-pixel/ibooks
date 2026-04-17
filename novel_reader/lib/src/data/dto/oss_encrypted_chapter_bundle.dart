import 'dart:convert';

/// OSS 上加密章節 JSON 外殼，與 [docs/BACKEND_CHAPTER_CONTENT.md] 對齊。
class OssEncryptedChapterBundle {
  const OssEncryptedChapterBundle({
    required this.format,
    required this.algorithm,
    required this.ivBase64,
    required this.cipherTextBase64,
  });

  final String format;
  final String algorithm;
  final String ivBase64;
  final String cipherTextBase64;

  static const supportedFormat = 'ibooks-chapter-encrypted-v1';
  static const supportedAlgorithm = 'AES-256-CBC-PKCS7';

  factory OssEncryptedChapterBundle.fromJson(Map<String, dynamic> json) {
    return OssEncryptedChapterBundle(
      format: json['format'] as String? ?? '',
      algorithm: json['algorithm'] as String? ?? '',
      ivBase64: json['ivBase64'] as String? ?? '',
      cipherTextBase64: json['cipherTextBase64'] as String? ?? '',
    );
  }

  factory OssEncryptedChapterBundle.parse(String raw) {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return OssEncryptedChapterBundle.fromJson(map);
  }

  void validate() {
    if (format != supportedFormat) {
      throw FormatException('Unsupported format: $format');
    }
    if (algorithm != supportedAlgorithm) {
      throw FormatException('Unsupported algorithm: $algorithm');
    }
    if (ivBase64.isEmpty || cipherTextBase64.isEmpty) {
      throw FormatException('Missing iv or ciphertext');
    }
  }
}
