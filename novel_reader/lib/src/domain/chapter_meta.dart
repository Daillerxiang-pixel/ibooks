/// 與後端章節列表／詳情對齊：不包含正文，只含 OSS 與解鎖信息。
class ChapterMeta {
  const ChapterMeta({
    required this.id,
    required this.bookId,
    required this.title,
    required this.sortOrder,
    required this.isFree,
    required this.contentOssUrls,
    this.contentKeyBase64,
    this.isEncrypted = false,
  });

  final String id;
  final String bookId;
  final String title;
  final int sortOrder;
  final bool isFree;

  /// 至少一個 OSS JSON 地址；付費章解密前需 [contentKeyBase64]。
  final List<String> contentOssUrls;

  /// 購買成功後由後端下發；免費明文 OSS 時可為 null。
  final String? contentKeyBase64;

  /// 與後端 `content_is_encrypted` 對齊；免費章也可能為加密 OSS 測試。
  final bool isEncrypted;

  bool get needsDecryption => isEncrypted;
}
