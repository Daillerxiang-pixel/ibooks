import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 全書閱讀器橫向留白與內容最大寬（手機大屏兩側留空，避免「撐滿過寬」）。
abstract final class AppLayout {
  /// 與屏幕邊緣的最小間距（dp）
  static const double screenGutter = 18;

  /// 主內容欄最大寬度（在寬屏上居中，兩側自然留空）
  static const double contentMaxWidth = 372;

  /// 當前路由下內容區可用寬度（已扣兩側 gutter，且不超過 [contentMaxWidth]）
  static double contentWidthFor(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return math.min(contentMaxWidth, w - screenGutter * 2);
  }
}
