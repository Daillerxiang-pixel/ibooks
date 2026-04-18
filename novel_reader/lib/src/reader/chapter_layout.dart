import 'package:flutter/material.dart';

/// 整章一次性排版的結果。
///
/// 把 **整章** 的 [TextSpan] 用一個 [TextPainter] 排版到固定寬度 [pageWidth]，
/// 然後按 [contentH]（每頁可顯示的精確高度）切分成 [pageCount] 頁。
///
/// 渲染時，每頁通過 [paintPage] 把 painter 平移 `pageIndex * contentH` 像素再繪製，
/// 配合 `ClipRect(size: pageWidth × contentH)` 即可得到「**整頁完全鋪滿、無底部空白**」的效果。
///
/// 這是 KOReader / Foliate / flutter_ebook_app 等開源閱讀器的通用做法：
/// **layout once, paint many windows**。
class ChapterLayout {
  ChapterLayout._({
    required this.painter,
    required this.pageWidth,
    required this.contentH,
    required this.pageCount,
  });

  final TextPainter painter;
  final double pageWidth;
  final double contentH;
  final int pageCount;

  /// 把整章按指定樣式排版，並按 `contentH` 切頁。
  factory ChapterLayout.layout({
    required String fullText,
    required TextStyle style,
    StrutStyle? strutStyle,
    required double pageWidth,
    required double contentH,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: fullText, style: style),
      textDirection: TextDirection.ltr,
      maxLines: null,
      strutStyle: strutStyle,
      textAlign: TextAlign.justify,
    )..layout(maxWidth: pageWidth);

    int pages;
    if (contentH <= 0) {
      pages = 1;
    } else {
      pages = (tp.size.height / contentH).ceil().clamp(1, 100000);
    }
    return ChapterLayout._(
      painter: tp,
      pageWidth: pageWidth,
      contentH: contentH,
      pageCount: pages,
    );
  }

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
