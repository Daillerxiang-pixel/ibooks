import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../src/data/reader_settings.dart';

/// 閱讀器設置面板（底部彈出）：字號、行距檔位、背景、字體、翻頁方式
class ReaderSettingsSheet extends StatelessWidget {
  const ReaderSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    final settings = context.read<ReaderSettings>();
    return showModalBottomSheet(
      context: context,
      backgroundColor: settings.theme.chromeBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider<ReaderSettings>.value(
        value: settings,
        child: const ReaderSettingsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<ReaderSettings>();
    final fg = s.theme.fg;
    final subtle = s.theme.subtle;

    Widget label(String t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(t, style: GoogleFonts.notoSansTc(fontSize: 12.5, color: subtle, fontWeight: FontWeight.w600)),
        );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: subtle, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 14),

            // 字號
            label('字號  ${s.fontSize.toStringAsFixed(0)}'),
            Row(
              children: [
                _StepBtn(icon: 'A−', fg: fg, onTap: () => s.setFontSize(s.fontSize - 1)),
                Expanded(
                  child: Slider(
                    value: s.fontSize,
                    min: ReaderSettings.minFontSize,
                    max: ReaderSettings.maxFontSize,
                    divisions: (ReaderSettings.maxFontSize - ReaderSettings.minFontSize).toInt(),
                    onChanged: s.setFontSize,
                  ),
                ),
                _StepBtn(icon: 'A+', fg: fg, onTap: () => s.setFontSize(s.fontSize + 1)),
              ],
            ),
            const SizedBox(height: 8),

            // 行距：低/中/高
            label('行距'),
            Row(
              children: [
                for (final ls in LineSpacing.values) ...[
                  Expanded(
                    child: _Chip(
                      label: ls.label,
                      selected: s.lineSpacing == ls,
                      onTap: () => s.setLineSpacing(ls),
                      fg: fg,
                      subtle: subtle,
                    ),
                  ),
                  if (ls != LineSpacing.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 背景
            label('背景'),
            Row(
              children: [
                for (final t in ReaderTheme.values) ...[
                  Expanded(
                    child: _ThemeSwatch(
                      theme: t,
                      selected: s.theme == t,
                      onTap: () => s.setTheme(t),
                    ),
                  ),
                  if (t != ReaderTheme.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 字體
            label('字體'),
            Row(
              children: [
                for (final f in ReaderFontFamily.values) ...[
                  Expanded(
                    child: _FontChip(
                      family: f,
                      selected: s.family == f,
                      onTap: () => s.setFamily(f),
                      fg: fg,
                      subtle: subtle,
                    ),
                  ),
                  if (f != ReaderFontFamily.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // 翻頁方式
            label('翻頁'),
            Row(
              children: [
                for (final m in PageTurnMode.values) ...[
                  Expanded(
                    child: _Chip(
                      label: m.label,
                      selected: s.pageMode == m,
                      onTap: () => s.setPageMode(m),
                      fg: fg,
                      subtle: subtle,
                    ),
                  ),
                  if (m != PageTurnMode.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.fg, required this.onTap});
  final String icon;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: fg.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(icon, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme, required this.selected, required this.onTap});
  final ReaderTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 1.6,
        child: Container(
          decoration: BoxDecoration(
            color: theme.bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? const Color(0xFF8B3A2E) : theme.fg.withOpacity(0.12),
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(theme.label, style: TextStyle(color: theme.fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _FontChip extends StatelessWidget {
  const _FontChip({
    required this.family,
    required this.selected,
    required this.onTap,
    required this.fg,
    required this.subtle,
  });
  final ReaderFontFamily family;
  final bool selected;
  final VoidCallback onTap;
  final Color fg;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    final ts = family == ReaderFontFamily.serif
        ? GoogleFonts.notoSerifTc(fontSize: 14, color: fg, fontWeight: FontWeight.w600)
        : GoogleFonts.notoSansTc(fontSize: 14, color: fg, fontWeight: FontWeight.w600);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF8B3A2E) : subtle, width: selected ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(family.label, style: ts),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.fg,
    required this.subtle,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color fg;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF8B3A2E) : subtle, width: selected ? 2 : 1),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.notoSansTc(fontSize: 13, color: fg, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}
