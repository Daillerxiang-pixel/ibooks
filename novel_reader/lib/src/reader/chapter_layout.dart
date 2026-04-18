import 'package:flutter/material.dart';

/// 整章一次性排版的結果，支持「混合行高」（如標題加大加粗、正文常規）。
///
/// 1. 把整章 [InlineSpan] 用一個 [TextPainter] 排版到 [pageWidth] 寬。
/// 2. 從 painter 的 [LineMetrics] 取出每一行的精確位置，按可用高度
///    [availableHeight] 切頁——遇到加入下一行會超高的位置，就在那裡開新頁。
/// 3. 提供 [paintPage] / [pageHeight]：頁高可能略小於 `availableHeight`，
///    渲染端對應 `Container(height: availableHeight)` + 內部 `ClipRect(SizedBox(height: pageHeight(i)))`，
///    既保證所有頁外觀一致高度，又不會在頁底「漏出」下一頁的首行。
class ChapterLayout {
  ChapterLayout._({
    required this.painter,
    required this.pageWidth,
    required this.availableHeight,
    required this.pageStarts,
  });

  final TextPainter painter;
  final double pageWidth;
  final double availableHeight;

  /// 每一頁第 1 行在 [painter] 中的 y 起點（單位：邏輯像素）。
  final List<double> pageStarts;

  int get pageCount => pageStarts.length;

  /// 第 [i] 頁實際渲染的高度（≤ [availableHeight]）。最後一頁取 painter 末尾。
  double pageHeight(int i) {
    if (i + 1 < pageStarts.length) {
      return pageStarts[i + 1] - pageStarts[i];
    }
    return painter.size.height - pageStarts[i];
  }

  factory ChapterLayout.layout({
    required InlineSpan textSpan,
    StrutStyle? strutStyle,
    required double pageWidth,
    required double availableHeight,
  }) {
    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
      strutStyle: strutStyle,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: pageWidth);

    final lines = tp.computeLineMetrics();
    if (lines.isEmpty || availableHeight <= 0) {
      return ChapterLayout._(
        painter: tp,
        pageWidth: pageWidth,
        availableHeight: availableHeight,
        pageStarts: const [0.0],
      );
    }

    // 行邊界對齊地分頁，避免半字截斷
    final breaks = <double>[0];
    double pageStartY = 0;
    for (final lm in lines) {
      final lineTop = lm.baseline - lm.ascent;
      final lineBottom = lm.baseline + lm.descent;
      // 若加入這一行會超出可用高度，則將本行作為下一頁的起點
      if (lineBottom - pageStartY > availableHeight + 0.5) {
        pageStartY = lineTop;
        breaks.add(pageStartY);
      }
    }
    return ChapterLayout._(
      painter: tp,
      pageWidth: pageWidth,
      availableHeight: availableHeight,
      pageStarts: breaks,
    );
  }

  /// 把整章 painter 平移後繪製，由外層 ClipRect 限制只顯示本頁區域。
  void paintPage(Canvas canvas, int pageIndex) {
    canvas.save();
    canvas.translate(0, -pageStarts[pageIndex]);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void dispose() {
    painter.dispose();
  }
}
