import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/ibooks_colors.dart';
import '../../widgets/book_covers.dart';
import '../../widgets/section_title_row.dart';

class CategoryTab extends StatelessWidget {
  const CategoryTab({super.key});

  static const _cats = [
    ('🏙', '都市'),
    ('🏯', '古言'),
    ('⚔', '玄幻'),
    ('🔍', '懸疑'),
    ('💕', '甜寵'),
    ('🚀', '科幻'),
    ('🌊', '港風'),
    ('📚', '更多'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8),
      children: [
        const SectionTitleRow(title: '全部分類', marginTop: 0),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
          children: _cats.map((c) {
            final name = c.$2 == '更多' ? '全部' : c.$2;
            return InkWell(
              onTap: () => context.push('/catlist?cat=${Uri.encodeQueryComponent(name)}'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: IbColors.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 10)],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.$1, style: const TextStyle(fontSize: 26)),
                    const SizedBox(height: 6),
                    Text(
                      c.$2,
                      style: GoogleFonts.notoSansTc(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SectionTitleRow(title: '分類熱門', marginTop: 16),
        Row(
          children: [
            Expanded(child: _MiniBook(4, '霧島心事', '懸疑 · 付費', () => context.push('/detail'))),
            const SizedBox(width: 8),
            Expanded(child: _MiniBook(1, '霓虹深處…', '都市', () => context.push('/detail'))),
            const SizedBox(width: 8),
            Expanded(child: _MiniBook(6, '星塵旅人', '科幻', () => context.push('/detail'))),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MiniBook extends StatelessWidget {
  const _MiniBook(this.v, this.t, this.m, this.onTap);

  final int v;
  final String t;
  final String m;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BookCover(variant: v, borderRadius: 10),
          const SizedBox(height: 6),
          Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansTc(fontSize: 11.5, fontWeight: FontWeight.w500)),
          Text(m, style: GoogleFonts.notoSansTc(fontSize: 9.9, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}
