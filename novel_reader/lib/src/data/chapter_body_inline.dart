import 'dart:convert';

import '../domain/chapter_body.dart';

/// 庫內 [inline] 正文：優先按 [ChapterBody] JSON 解析，否則當單段純文字。
ChapterBody chapterBodyFromInlineString(String content) {
  final t = content.trim();
  if (t.isEmpty) {
    return const ChapterBody(version: 1, title: '', paragraphs: []);
  }
  try {
    final j = jsonDecode(t);
    if (j is Map<String, dynamic>) {
      return ChapterBody.fromJson(j);
    }
  } catch (_) {}
  return ChapterBody(version: 1, title: '', paragraphs: [content]);
}
