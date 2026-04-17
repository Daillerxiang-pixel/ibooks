import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/ibooks_colors.dart';
import '../../widgets/book_covers.dart';
import '../../widgets/section_title_row.dart';

class ShelfTab extends StatelessWidget {
  const ShelfTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 6),
      children: [
        SectionTitleRow(
          title: '最近閱讀',
          marginTop: 0,
          trailing: Text(
            '管理',
            style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent),
          ),
        ),
        _ShelfRow(
          cover: 1,
          title: '霓虹深處的約定',
          meta: '讀至 第 42 章 · 上次 2 小時前',
          progress: 0.38,
          onTap: () => context.push('/reader'),
        ),
        _ShelfRow(
          cover: 2,
          title: '海風與舊信箋',
          meta: '已加入書架 · 未開始',
          progress: 0,
          onTap: () => context.push('/detail'),
        ),
        const SectionTitleRow(title: '書架收藏'),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _ShelfBook(v: 3, title: '南洋夜雨錄', meta: '付費連載', onTap: () => context.push('/detail'))),
              const SizedBox(width: 8),
              Expanded(child: _ShelfBook(v: 4, title: '霧島心事', meta: '懸疑', onTap: () => context.push('/detail'))),
              const SizedBox(width: 8),
              Expanded(child: _ShelfBook(v: 5, title: '半城煙火', meta: '古言', onTap: () => context.push('/detail'))),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _ShelfRow extends StatelessWidget {
  const _ShelfRow({
    required this.cover,
    required this.title,
    required this.meta,
    required this.progress,
    required this.onTap,
  });

  final int cover;
  final String title;
  final String meta;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(width: 56, child: BookCover(variant: cover, aspectRatio: 3 / 4, borderRadius: 8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSansTc(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(meta, style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: IbColors.line,
                      color: IbColors.accent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShelfBook extends StatelessWidget {
  const _ShelfBook({required this.v, required this.title, required this.meta, required this.onTap});

  final int v;
  final String title;
  final String meta;
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
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansTc(fontSize: 11.5, fontWeight: FontWeight.w500)),
          Text(meta, style: GoogleFonts.notoSansTc(fontSize: 9.9, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}
