import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 「閱讀進度」存儲：每本書記錄上次讀到的章節 + 頁碼 + 章內總頁數 + 時間戳。
/// 用 [SharedPreferences] 持久化，鍵 = `reading_progress_v1.bookId`。
///
/// 寫入做了輕量節流（500ms），避免頻繁翻頁時頻繁落盤。
class ReadingProgressStore {
  ReadingProgressStore._();
  static final ReadingProgressStore instance = ReadingProgressStore._();

  static const _kPrefix = 'reading_progress_v1.';

  Timer? _flushTimer;
  Map<String, dynamic>? _pendingValue;
  String? _pendingKey;

  String _key(int bookId) => '$_kPrefix$bookId';

  Future<ReadingProgress?> load(int bookId) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(bookId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final j = jsonDecode(raw);
      if (j is Map<String, dynamic>) return ReadingProgress.fromJson(j);
    } catch (_) {}
    return null;
  }

  /// 節流寫入。立即更新內存中的待寫值，500ms 後落盤。
  void save(int bookId, ReadingProgress p) {
    _pendingKey = _key(bookId);
    _pendingValue = p.toJson();
    _flushTimer?.cancel();
    _flushTimer = Timer(const Duration(milliseconds: 500), _flush);
  }

  /// 立刻寫入（如離開閱讀器時）
  Future<void> flush() async {
    _flushTimer?.cancel();
    await _flush();
  }

  Future<void> _flush() async {
    final k = _pendingKey;
    final v = _pendingValue;
    if (k == null || v == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(k, jsonEncode(v));
  }

  Future<void> clear(int bookId) async {
    _flushTimer?.cancel();
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(bookId));
  }
}

class ReadingProgress {
  ReadingProgress({
    required this.chapterId,
    required this.pageIndex,
    required this.totalPages,
    required this.scrollOffset,
    required this.updatedAt,
  });

  final int chapterId;

  /// 分頁模式下的當前頁（0-based）
  final int pageIndex;

  /// 分頁模式下的總頁數，用於估算進度百分比
  final int totalPages;

  /// 上下滑模式下的滾動偏移（像素）
  final double scrollOffset;

  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'chapterId': chapterId,
        'pageIndex': pageIndex,
        'totalPages': totalPages,
        'scrollOffset': scrollOffset,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory ReadingProgress.fromJson(Map<String, dynamic> j) => ReadingProgress(
        chapterId: (j['chapterId'] as num?)?.toInt() ?? 0,
        pageIndex: (j['pageIndex'] as num?)?.toInt() ?? 0,
        totalPages: (j['totalPages'] as num?)?.toInt() ?? 1,
        scrollOffset: (j['scrollOffset'] as num?)?.toDouble() ?? 0,
        updatedAt:
            DateTime.tryParse(j['updatedAt']?.toString() ?? '') ?? DateTime.now(),
      );
}
