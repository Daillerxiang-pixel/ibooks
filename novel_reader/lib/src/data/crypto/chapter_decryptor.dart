import 'dart:convert';

import 'package:encrypt/encrypt.dart' as enc;

import '../dto/oss_encrypted_chapter_bundle.dart';

/// 使用購買後獲得的密鑰解密 OSS 上的加密 JSON 包。
class ChapterDecryptor {
  /// [keyBase64]：AES-256 密鑰的 base64（32 bytes）。
  String decryptBundleToUtf8(
    OssEncryptedChapterBundle bundle,
    String keyBase64,
  ) {
    bundle.validate();
    final key = enc.Key.fromBase64(keyBase64);
    final iv = enc.IV.fromBase64(bundle.ivBase64);
    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    );
    final decrypted = encrypter.decrypt(
      enc.Encrypted.fromBase64(bundle.cipherTextBase64),
      iv: iv,
    );
    return decrypted;
  }

  /// 解密後再解析為 [ChapterBody] 的 JSON 字符串。
  Map<String, dynamic> decryptToChapterJson(
    OssEncryptedChapterBundle bundle,
    String keyBase64,
  ) {
    final utf8Text = decryptBundleToUtf8(bundle, keyBase64);
    final map = jsonDecode(utf8Text);
    if (map is! Map<String, dynamic>) {
      throw FormatException('Decrypted payload is not a JSON object');
    }
    return map;
  }
}
