/// 解密後（或免費明文 OSS）的章節正文結構，需與後端生成一致。
class ChapterBody {
  const ChapterBody({
    required this.version,
    required this.title,
    required this.paragraphs,
  });

  final int version;
  final String title;
  final List<String> paragraphs;

  factory ChapterBody.fromJson(Map<String, dynamic> json) {
    final raw = json['paragraphs'];
    final list = raw is List
        ? raw.map((e) => e.toString()).toList()
        : <String>[];
    return ChapterBody(
      version: (json['version'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? '',
      paragraphs: list,
    );
  }

  String get plainText => paragraphs.join('\n\n');
}
