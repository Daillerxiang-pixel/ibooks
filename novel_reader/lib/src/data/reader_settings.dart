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

class ReaderSettings extends ChangeNotifier {
  static const _kTheme = 'reader_theme';
  static const _kFontSize = 'reader_font_size';
  static const _kLineHeight = 'reader_line_height';
  static const _kFontFamily = 'reader_font_family';

  static const double minFontSize = 14;
  static const double maxFontSize = 26;
  static const double minLineHeight = 1.4;
  static const double maxLineHeight = 2.4;

  ReaderTheme _theme = ReaderTheme.day;
  double _fontSize = 18;
  double _lineHeight = 1.85;
  ReaderFontFamily _family = ReaderFontFamily.sans;

  ReaderTheme get theme => _theme;
  double get fontSize => _fontSize;
  double get lineHeight => _lineHeight;
  ReaderFontFamily get family => _family;

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
    _lineHeight = (p.getDouble(_kLineHeight) ?? _lineHeight).clamp(minLineHeight, maxLineHeight);
    final fam = p.getString(_kFontFamily);
    if (fam != null) {
      _family = ReaderFontFamily.values.firstWhere(
        (e) => e.name == fam,
        orElse: () => ReaderFontFamily.sans,
      );
    }
    notifyListeners();
  }

  Future<void> setTheme(ReaderTheme v) async {
    if (_theme == v) return;
    _theme = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kTheme, v.name);
  }

  /// 等同於日／夜模式快速切換
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

  Future<void> setLineHeight(double v) async {
    final c = double.parse(v.clamp(minLineHeight, maxLineHeight).toStringAsFixed(2));
    if (c == _lineHeight) return;
    _lineHeight = c;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kLineHeight, c);
  }

  Future<void> setFamily(ReaderFontFamily v) async {
    if (_family == v) return;
    _family = v;
    notifyListeners();
    final p = await SharedPreferences.getInstance();
    await p.setString(_kFontFamily, v.name);
  }
}
