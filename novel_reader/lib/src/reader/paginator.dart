import 'package:flutter/material.dart';

/// 將整章正文按給定樣式 + 頁面尺寸切成若干「整頁」字符串。
/// 採用二分法：每頁找到能完全容納在 [size] 內的最長前綴，再嘗試在「。！？」等
/// 自然斷點上回退，避免句子被切到下一頁開頭。
class ChapterPaginator {
  ChapterPaginator({
    required this.fullText,
    required this.style,
    required this.size,
    this.strutStyle,
  });

  final String fullText;
  final TextStyle style;

  /// 一頁可顯示文本的可用區域（已扣除外部 padding）
  final Size size;
  final StrutStyle? strutStyle;

  List<String> paginate() {
    if (fullText.isEmpty || size.width <= 0 || size.height <= 0) {
      return [fullText];
    }
    final pages = <String>[];
    String remaining = _trimLeadingBlank(fullText);
    while (remaining.isNotEmpty) {
      // 整段已能放下：作為最後一頁結束
      if (_heightOf(remaining) <= size.height + 0.5) {
        pages.add(remaining);
        break;
      }
      // 二分搜索最長能放下的前綴長度
      int lo = 1;
      int hi = remaining.length;
      int best = 1;
      while (lo <= hi) {
        final mid = (lo + hi) >> 1;
        final h = _heightOf(remaining.substring(0, mid));
        if (h <= size.height + 0.5) {
          best = mid;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      // 在標點處回退（最多 60 字），讓段落更自然
      best = _preferBreak(remaining, best);
      pages.add(remaining.substring(0, best));
      remaining = _trimLeadingBlank(remaining.substring(best));
      if (pages.length > 5000) break;
    }
    if (pages.isEmpty) pages.add('');
    return pages;
  }

  double _heightOf(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
      strutStyle: strutStyle,
    )..layout(maxWidth: size.width);
    final h = tp.size.height;
    tp.dispose();
    return h;
  }

  int _preferBreak(String text, int end) {
    const maxBack = 60;
    final lower = (end - maxBack).clamp(1, end);
    for (int i = end - 1; i >= lower; i--) {
      final ch = text[i];
      if (ch == '\n' ||
          ch == '。' ||
          ch == '！' ||
          ch == '？' ||
          ch == '」' ||
          ch == '”' ||
          ch == '；') {
        return i + 1;
      }
    }
    return end;
  }

  String _trimLeadingBlank(String s) {
    int i = 0;
    while (i < s.length && (s[i] == '\n' || s[i] == ' ' || s[i] == '\u3000')) {
      i++;
    }
    return s.substring(i);
  }
}
