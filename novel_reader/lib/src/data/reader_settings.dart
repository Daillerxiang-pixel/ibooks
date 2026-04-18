import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 閱讀器主題（背景/文字色搭配）
enum ReaderTheme { day, sepia, dark }

extension ReaderThemeExt on ReaderTheme {
  String get label {
    switch (this) {
      case ReaderTheme.day:
        return '日間';
      case ReaderTheme.sepia:
        return '羊皮紙';
      case ReaderTheme.dark:
        return '夜間';
    }
  }

  Color get bg {
    switch (this) {
      case ReaderTheme.day:
        return const Color(0xFFF7F4EE);
      case ReaderTheme.sepia:
        return const Color(0xFFEFE6D2);
      case ReaderTheme.dark:
        return const Color(0xFF1B1916);
    }
  }

  Color get fg {
    switch (this) {
      case ReaderTheme.day:
        return const Color(0xFF1A1A1A);
      case ReaderTheme.sepia:
        return const Color(0xFF3A2F1F);
      case ReaderTheme.dark:
        return const Color(0xFFD9D2C5);
    }
  }

  /// 控件條（頂部/底部疊浮層）背景色
  Color get chromeBg {
    switch (this) {
      case ReaderTheme.day:
        return const Color(0xF2FFFFFF);
      case ReaderTheme.sepia:
        return const Color(0xF2EFE6D2);
      case ReaderTheme.dark:
        return const Color(0xF21B1916);
    }
  }

  /// 副文字 / 線條色
  Color get subtle {
    switch (this) {
      case ReaderTheme.day:
        return const Color(0x66000000);
      case ReaderTheme.sepia:
        return const Color(0x665C4A2F);
      case ReaderTheme.dark:
        return const Color(0x66D9D2C5);
    }
  }

  Brightness get brightness => this == ReaderTheme.dark ? Brightness.dark : Brightness.light;
}

/// 字體（系統默認 = 與全 App 同一套 Noto Sans TC；宋體 = Noto Serif TC）
enum ReaderFontFamily { sans, serif }

extension ReaderFontFamilyExt on ReaderFontFamily {
  String get label => this == ReaderFontFamily.sans ? '黑體' : '宋體';
}

/// 行距檔位：低 / 中 / 高
enum LineSpacing { low, medium, high }

extension LineSpacingExt on LineSpacing {
  String get label {
    switch (this) {
      case LineSpacing.low:
        return '低';
      case LineSpacing.medium:
        return '中';
      case LineSpacing.high:
        return '高';
    }
  }

  /// 對應實際 line-height 倍數
  double get value {
    switch (this) {
      case LineSpacing.low:
        return 1.55;
      case LineSpacing.medium:
        return 1.85;
      case LineSpacing.high:
        return 2.20;
    }
  }
}

/// 翻頁方式
enum PageTurnMode { scroll, slide, curl }

extension PageTurnModeExt on PageTurnMode {
  String get label {
    switch (this) {
      case PageTurnMode.scroll:
        return '上下滑';
      case PageTurnMode.slide:
        return '左右翻';
      case PageTurnMode.curl:
        return '仿真翻';
    }
  }
}

/// 頁面左右內邊距檔位（影響每頁可顯示寬度）
enum PageMargin { small, medium, large }

extension PageMarginExt on PageMargin {
  String get label {
    switch (this) {
      case PageMargin.small:
        return '窄';
      case PageMargin.medium:
        return '中';
      case PageMargin.large:
        return '寬';
    }
  }

  double get value {
    switch (this) {
      case PageMargin.small:
        return 12;
      case PageMargin.medium:
        return 20;
      case PageMargin.large:
        return 32;
    }
  }
}

class ReaderSettings extends ChangeNotifier {
  static const _kTheme = 'reader_theme';
  static const _kFontSize = 'reader_font_size';
  static const _kLineSpacing = 'reader_line_spacing_v2';
  static const _kFontFamily = 'reader_font_family';
  static const _kPageMode = 'reader_page_mode';
  static const _kBrightness = 'reader_brightness';
  static const _kPageMargin = 'reader_page_margin';
  static const _kKeepScreenOn = 'reader_keep_screen_on';

  static const double minFontSize = 14;
  static const double maxFontSize = 26;

  ReaderTheme _theme = ReaderTheme.day;
  double _fontSize = 18;
  LineSpacing _lineSpacing = LineSpacing.medium;
  ReaderFontFamily _family = ReaderFontFamily.sans;
  PageTurnMode _pageMode = PageTurnMode.scroll;
  /// 螢幕亮度覆蓋層透明度：1.0 = 最亮（無遮罩），0.2 = 最暗
  double _brightness = 1.0;
  PageMargin _pageMargin = PageMargin.medium;
  bool _keepScreenOn = true;

  ReaderTheme get theme => _theme;
  double get fontSize => _fontSize;
  LineSpacing get lineSpacing => _lineSpacing;
  double get lineHeight => _lineSpacing.value;
  ReaderFontFamily get family => _family;
  PageTurnMode get pageMode => _pageMode;
  double get brightness => _brightness;
  PageMargin get pageMargin => _pageMargin;
  bool get keepScreenOn => _keepScreenOn;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kTheme);
    if (t != null) {
      _theme = ReaderTheme.values.firstWhere(
        (e) => e.name == t,
        orElse: () => ReaderTheme.day,
      );
    }
    _fontSize = (p.getDouble(_kFontSize) ?? _fontSize).clamp(minFontSize, maxFontSize);
    final ls = p.getString(_kLineSpacing);
    if (ls != null) {
      _lineSpacing = LineSpacing.values.firstWhere(
        (e) => e.name == ls,
        orElse: () => LineSpacing.medium,
      );
    }
    final fam = p.getString(_kFontFamily);
    if (fam != null) {
      _family = ReaderFontFamily.values.firstWhere(
        (e) => e.name == fam,
        orElse: () => ReaderFontFamily.sans,
      );
    }
    final pm = p.getString(_kPageMode);
    if (pm != null) {
      _pageMode = PageTurnMode.values.firstWhere(
        (e) => e.name == pm,
        orElse: () => PageTurnMode.scroll,
      );
    }
    _brightness = (p.getDouble(_kBrightness) ?? 1.0).clamp(0.2, 1.0);
    final pmg = p.getString(_kPageMargin);
    if (pmg != null) {
      _pageMargin = PageMargin.values.firstWhere(
        (e) => e.name == pmg,
        orElse: () => PageMargin.medium,
      );
    }
    _keepScreenOn = p.getBool(_kKeepScreenOn) ?? true;
    notifyListeners();
  }

  Future<void> setTheme(ReaderTheme v) async {
    if (_theme == v) return;
    _theme = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTheme, v.name);
  }

  Future<void> toggleDayNight() async {
    await setTheme(_theme == ReaderTheme.dark ? ReaderTheme.day : ReaderTheme.dark);
  }

  Future<void> setFontSize(double v) async {
    final c = v.clamp(minFontSize, maxFontSize).toDouble();
    if (c == _fontSize) return;
    _fontSize = c;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kFontSize, c);
  }

  Future<void> setLineSpacing(LineSpacing v) async {
    if (_lineSpacing == v) return;
    _lineSpacing = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLineSpacing, v.name);
  }

  Future<void> setFamily(ReaderFontFamily v) async {
    if (_family == v) return;
    _family = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFontFamily, v.name);
  }

  Future<void> setPageMode(PageTurnMode v) async {
    if (_pageMode == v) return;
    _pageMode = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPageMode, v.name);
  }

  Future<void> setBrightness(double v) async {
    final c = v.clamp(0.2, 1.0);
    if ((c - _brightness).abs() < 0.01) return;
    _brightness = c;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kBrightness, c);
  }

  Future<void> setPageMargin(PageMargin v) async {
    if (_pageMargin == v) return;
    _pageMargin = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPageMargin, v.name);
  }

  Future<void> setKeepScreenOn(bool v) async {
    if (_keepScreenOn == v) return;
    _keepScreenOn = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kKeepScreenOn, v);
  }
}
