import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/book_covers.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class BrowseHistoryScreen extends StatelessWidget {
  const BrowseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '瀏覽記錄',
      subtitle: '最近看過的書',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('最近瀏覽', style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _Row(1, '霓虹深處的約定', '讀至 第 4 章 · 今日 21:18', () => context.push('/detail')),
          _Row(2, '海風與舊信箋', '試讀 第 1 章 · 昨日', () => context.push('/detail')),
          _Row(3, '南洋夜雨錄', '書籍詳情 · 三日前', () => context.push('/detail')),
          const SizedBox(height: 8),
          Text('點一列進入書籍詳情（原型）。', textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.v, this.t, this.m, this.onTap);

  final int v;
  final String t;
  final String m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 44, height: 58, child: BookCover(variant: v, borderRadius: 6, aspectRatio: 44 / 58)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t, style: GoogleFonts.notoSansTc(fontSize: 13.1, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(m, style: GoogleFonts.notoSansTc(fontSize: 10.9, color: IbColors.inkMuted)),
                ],
              ),
            ),
            const Text('›', style: TextStyle(color: IbColors.inkMuted, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
