import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_reader/src/data/crypto/chapter_decryptor.dart';
import 'package:novel_reader/src/data/dto/oss_encrypted_chapter_bundle.dart';

void main() {
  test('AES bundle roundtrip matches OSS format', () {
    final key = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);
    const plain = '{"version":1,"title":"章","paragraphs":["a","b"]}';
    final encrypter = enc.Encrypter(
      enc.AES(key, mode: enc.AESMode.cbc, padding: 'PKCS7'),
    );
    final encrypted = encrypter.encrypt(plain, iv: iv);
    final bundle = OssEncryptedChapterBundle(
      format: OssEncryptedChapterBundle.supportedFormat,
      algorithm: OssEncryptedChapterBundle.supportedAlgorithm,
      ivBase64: iv.base64,
      cipherTextBase64: encrypted.base64,
    );
    final out = ChapterDecryptor().decryptBundleToUtf8(bundle, key.base64);
    expect(out, plain);
  });
}
