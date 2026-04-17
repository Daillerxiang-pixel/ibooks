import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ibooks_colors.dart';

class IbTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: IbColors.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: IbColors.accent,
        brightness: Brightness.light,
        surface: IbColors.bgCard,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.notoSansTcTextTheme(base.textTheme).apply(
        bodyColor: IbColors.ink,
        displayColor: IbColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: IbColors.bg.withOpacity(0.94),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.notoSansTc(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: IbColors.ink,
        ),
        iconTheme: const IconThemeData(color: IbColors.ink),
      ),
      dividerColor: IbColors.line,
      cardTheme: CardTheme(
        color: IbColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
