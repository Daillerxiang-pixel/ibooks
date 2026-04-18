import 'package:flutter/material.dart';

/// 整章一次性排版的結果。
///
/// 把 **整章** 的 [TextSpan] 用一個 [TextPainter] 排版到固定寬度 [pageWidth]，
/// 然後依「該排版實際測得的行高」按行邊界切頁，
/// 從根本上避免「sub-pixel 截斷」造成的「最後一行只剩半個字」。
///
/// 這是 KOReader / Foliate / flutter_ebook_app 等開源閱讀器的通用做法：
/// **layout once, paint many windows**，但窗口邊界 **必須與實測行邊界對齊**。
class ChapterLayout {
  ChapterLayout._({
    required this.painter,
    required this.pageWidth,
    required this.contentH,
    required this.lineH,
    required this.linesPerPage,
    required this.pageCount,
  });

  final TextPainter painter;
  final double pageWidth;

  /// 一頁實際顯示文本的高度（= linesPerPage × 實測行高），與切片像素一致
  final double contentH;

  /// 實測單行高度（取自 [TextPainter.computeLineMetrics] 首行）
  final double lineH;

  final int linesPerPage;
  final int pageCount;

  /// 給定 **可用文本區的高度上限** [availableHeight]，自動：
  /// 1. 拿樣式排版整章；
  /// 2. 從 painter 取「實際行高」；
  /// 3. 計算每頁能放下幾行 → `contentH = linesPerPage × 實際行高`；
  /// 4. 切頁時保證 `contentH × pageCount ≥ painter.size.height`。
  factory ChapterLayout.layout({
    required String fullText,
    required TextStyle style,
    StrutStyle? strutStyle,
    required double pageWidth,
    required double availableHeight,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: fullText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
      strutStyle: strutStyle,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: pageWidth);

    // 用 painter 實測的行高（包含字體 ascent/descent/leading），
    // 與切頁邊界保持「像素級一致」，避免每頁底部切到字。
    final lineMetrics = tp.computeLineMetrics();
    final actualLineH = lineMetrics.isNotEmpty
        ? lineMetrics.first.height
        : (style.fontSize ?? 16) * (style.height ?? 1.0);

    int linesPerPage = (availableHeight / actualLineH).floor();
    if (linesPerPage < 1) linesPerPage = 1;
    final contentH = linesPerPage * actualLineH;

    final pageCount = contentH <= 0
        ? 1
        : (tp.size.height / contentH).ceil().clamp(1, 100000);

    return ChapterLayout._(
      painter: tp,
      pageWidth: pageWidth,
      contentH: contentH,
      lineH: actualLineH,
      linesPerPage: linesPerPage,
      pageCount: pageCount,
    );
  }

  /// 把整章 painter 的 `[pageIndex×contentH, (pageIndex+1)×contentH)` 區段畫到當前 canvas。
  /// 為避免 glyph 的 descent 略超出 strut 而被下一頁吃半個字，
  /// 我們僅讓最後一頁的繪製不被剪裁；其他頁的剪裁框完全等同 [contentH]，
  /// 而 painter 的所有字形仍以原坐標繪製（CustomPaint 外面的 ClipRect 會剪到 contentH 內）。
  void paintPage(Canvas canvas, int pageIndex) {
    canvas.save();
    canvas.translate(0, -pageIndex * contentH);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void dispose() {
    painter.dispose();
  }
}
