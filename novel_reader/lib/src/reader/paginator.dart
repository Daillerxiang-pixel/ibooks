import 'package:flutter/material.dart';

/// 行級分頁器
///
/// 給定 **整章**、**樣式**、**頁寬** 與「**每頁可容納行數** [linesPerPage]」，
/// 返回若干頁字符串：除最後一頁外，每頁的渲染高度恰為
/// `linesPerPage × lineHeight`，**頁底不會殘留空白**。
///
/// 實現方式：用 [TextPainter] 對整章做一次完整排版，
/// 透過 [TextPainter.computeLineMetrics] 知道每一行在原始排版中的位置，
/// 然後按行索引切分原文字符串。
class ChapterPaginator {
  ChapterPaginator({
    required this.fullText,
    required this.style,
    required this.pageWidth,
    required this.linesPerPage,
    required this.lineHeight,
    this.strutStyle,
  });

  final String fullText;
  final TextStyle style;
  final double pageWidth;
  final int linesPerPage;
  final double lineHeight;
  final StrutStyle? strutStyle;

  List<String> paginate() {
    if (fullText.isEmpty || pageWidth <= 0 || linesPerPage <= 0) {
      return [fullText];
    }

    final tp = TextPainter(
      text: TextSpan(text: fullText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
      strutStyle: strutStyle,
    )..layout(maxWidth: pageWidth);

    final lines = tp.computeLineMetrics();
    if (lines.isEmpty) {
      tp.dispose();
      return [fullText];
    }

    final pages = <String>[];
    for (int i = 0; i < lines.length; i += linesPerPage) {
      final endLine =
          (i + linesPerPage > lines.length) ? lines.length : i + linesPerPage;
      final startOffset = _offsetAtLineStart(tp, lines, i);
      final endOffset = (endLine >= lines.length)
          ? fullText.length
          : _offsetAtLineStart(tp, lines, endLine);
      var slice = fullText.substring(startOffset, endOffset);
      // 行尾的 `\n` 是上一行的終止符；若帶到下一頁開頭會多出一行空白
      if (slice.endsWith('\n')) {
        slice = slice.substring(0, slice.length - 1);
      }
      pages.add(slice);
    }

    tp.dispose();
    if (pages.isEmpty) pages.add(fullText);
    return pages;
  }

  /// 在第 [lineIndex] 行的起點查詢字符偏移
  int _offsetAtLineStart(
    TextPainter tp,
    List<LineMetrics> lines,
    int lineIndex,
  ) {
    if (lineIndex <= 0) return 0;
    final lm = lines[lineIndex];
    // 行頂坐標 = baseline - ascent；微微下沉 0.5 落入該行內部
    final y = lm.baseline - lm.ascent + 0.5;
    return tp.getPositionForOffset(Offset(0.5, y)).offset;
  }
}
