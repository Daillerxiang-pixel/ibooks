import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/chapter_list_args.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/book_covers.dart';
import '../widgets/ibooks_subpage_scaffold.dart';
import '../widgets/section_title_row.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '書籍詳情',
      subtitle: '目錄 · 試讀',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 104, child: BookCover(variant: 1, borderRadius: 10)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('霓虹深處的約定', style: GoogleFonts.notoSerifTc(fontSize: 18, fontWeight: FontWeight.w600, height: 1.25)),
                    const SizedBox(height: 6),
                    Text('作者：林晚澄 · 都市言情 · 港島背景', style: GoogleFonts.notoSansTc(fontSize: 11.8, color: IbColors.inkMuted, height: 1.45)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('付費閱讀 · 12 起', style: GoogleFonts.notoSansTc(fontSize: 16.3, fontWeight: FontWeight.w700, color: IbColors.accent)),
                        const SizedBox(width: 8),
                        Text('原 18', style: GoogleFonts.notoSansTc(fontSize: 12.2, color: IbColors.inkMuted, decoration: TextDecoration.lineThrough)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '繁體精校版。解鎖方式：按章付費 或 會員免費讀（若本書在會員書庫內）。可批量購章。',
            style: GoogleFonts.notoSansTc(fontSize: 12.8, height: 1.65, color: IbColors.inkMuted),
          ),
          const SectionTitleRow(title: '目錄', marginTop: 18),
          Material(
            color: IbColors.bgCard,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => context.push('/chapterlist', extra: const ChapterListArgs()),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('查看完整目錄', style: GoogleFonts.notoSansTc(fontSize: 13.5)),
                    Text('共 128 章 ›', style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('正文預覽', style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
          _ChapLine('第 1 章 起風了', '免費', false),
          _ChapLine('第 2 章 轉角咖啡館', '免費', false),
          const SectionTitleRow(title: '同類推送', marginTop: 18),
          Row(
            children: [
              Expanded(child: _PushBook(2, '海風與舊信箋', '都市 · 港風', () => context.push('/detail'))),
              const SizedBox(width: 8),
              Expanded(child: _PushBook(4, '霧島心事', '懸疑言情', () => context.push('/detail'))),
              const SizedBox(width: 8),
              Expanded(child: _PushBook(5, '半城煙火', '古言 · 完結', () => context.push('/detail'))),
            ],
          ),
          const SizedBox(height: 22),
          const Divider(height: 1, color: IbColors.line),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: IbColors.accent, padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () => context.push('/reader'),
                  child: Text('開始閱讀', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                  onPressed: () {},
                  child: Text('加入書架', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChapLine extends StatelessWidget {
  const _ChapLine(this.t, this.tag, this.lock);

  final String t;
  final String tag;
  final bool lock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t, style: GoogleFonts.notoSansTc(fontSize: 13.1)),
          Text(lock ? '🔒 付費' : tag, style: GoogleFonts.notoSansTc(fontSize: 11.5, color: lock ? IbColors.gold : IbColors.inkMuted)),
        ],
      ),
    );
  }
}

class _PushBook extends StatelessWidget {
  const _PushBook(this.v, this.t, this.m, this.onTap);

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
          Text(t, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansTc(fontSize: 11.5, fontWeight: FontWeight.w500)),
          Text(m, style: GoogleFonts.notoSansTc(fontSize: 9.9, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}
