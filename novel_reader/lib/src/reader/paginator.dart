import 'package:flutter/material.dart';

/// 把整章正文按給定樣式 + 頁面尺寸，切成若干「整頁」字符串。
/// 用 [TextPainter] 二分定位每頁能容納的最後一個字符位置。
class ChapterPaginator {
  ChapterPaginator({
    required this.fullText,
    required this.style,
    required this.size,
    this.strutStyle,
  });

  final String fullText;
  final TextStyle style;
  final Size size;
  final StrutStyle? strutStyle;

  List<String> paginate() {
    if (fullText.isEmpty || size.width <= 0 || size.height <= 0) {
      return [fullText];
    }
    final pages = <String>[];
    String remaining = fullText;
    while (remaining.isNotEmpty) {
      final tp = _layout(remaining);
      if (tp.size.height <= size.height + 0.5) {
        pages.add(remaining);
        break;
      }
      // 估計最後一個可顯示字符的位置
      final pos = tp.getPositionForOffset(Offset(size.width - 1, size.height));
      int end = pos.offset.clamp(1, remaining.length);
      // 線性回退，確保切片真的能放下，避免單行溢出
      end = _shrinkToFit(remaining, end);
      // 若處於英文/數字/標點末尾，盡量回退到一個自然斷點
      end = _preferBreak(remaining, end);
      pages.add(remaining.substring(0, end));
      remaining = remaining.substring(end);
      // 開頭如果是換行/空白，去掉以避免「上頁尾的空行」帶到下一頁頂部
      remaining = _trimLeadingBlank(remaining);
      if (pages.length > 5000) break; // 防護
    }
    if (pages.isEmpty) pages.add('');
    return pages;
  }

  TextPainter _layout(String text) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
      strutStyle: strutStyle,
    )..layout(maxWidth: size.width);
    return tp;
  }

  int _shrinkToFit(String text, int end) {
    int e = end;
    int guard = 0;
    while (e > 1 && guard < 200) {
      final tp = _layout(text.substring(0, e));
      if (tp.size.height <= size.height + 0.5) return e;
      e -= (e ~/ 32).clamp(1, 8);
      guard++;
    }
    return e.clamp(1, text.length);
  }

  int _preferBreak(String text, int end) {
    final maxBack = 40;
    final lower = (end - maxBack).clamp(1, end);
    for (int i = end - 1; i >= lower; i--) {
      final ch = text[i];
      if (ch == '\n' || ch == '。' || ch == '！' || ch == '？' || ch == '」' || ch == '”') {
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
