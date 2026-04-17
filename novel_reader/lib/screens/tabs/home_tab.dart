import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/ibooks_colors.dart';
import '../../widgets/book_covers.dart';
import '../../widgets/section_title_row.dart' show SectionTitleRow, HintLine;

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _chip = 0;
  final _chips = const ['都市', '古言', '玄幻', '懸疑', '甜寵'];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 12),
      children: [
        _HeroBanner(onTap: () => context.push('/detail')),
        SectionTitleRow(
          title: '本週強推',
          marginTop: 16,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: IbColors.accentSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('HOT', style: GoogleFonts.notoSansTc(fontSize: 9, color: IbColors.accent, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text('更多', style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent)),
            ],
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _HCard(1, '霓虹深處的約定', () => context.push('/detail')),
              _HCard(2, '海風與舊信箋', () => context.push('/detail'), v2: true),
              _HCard(1, '南洋夜雨錄', () => context.push('/detail')),
              _HCard(2, '霧島心事', () => context.push('/detail'), v2: true),
            ],
          ),
        ),
        const SectionTitleRow(title: '限時 · 橫幅專區', marginTop: 8),
        SizedBox(
          height: 150,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _WideCard(
                gradient: const LinearGradient(colors: [Color(0xFF2C3840), Color(0xFF4A6B7C)]),
                tag: '整本優惠',
                title: '批量購 8 折',
                sub: '整本解鎖更省 · 限時 48 小時',
                onTap: () => context.push('/detail'),
              ),
              const SizedBox(width: 10),
              _WideCard(
                gradient: const LinearGradient(colors: [Color(0xFF3D2838), Color(0xFF6B4A5C)]),
                tag: '會員專區',
                title: '會員暢讀書庫',
                sub: '標籤內作品暢讀 · 詳見會員權益',
                onTap: () => context.push('/detail'),
              ),
            ],
          ),
        ),
        const SectionTitleRow(title: '熱門分類', marginTop: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(_chips.length, (i) {
            final on = i == _chip;
            return ChoiceChip(
              label: Text(_chips[i], style: GoogleFonts.notoSansTc(fontSize: 11.5)),
              selected: on,
              onSelected: (_) => setState(() => _chip = i),
              selectedColor: IbColors.accentSoft,
              labelStyle: TextStyle(color: on ? IbColors.accent : IbColors.inkMuted, fontWeight: on ? FontWeight.w600 : FontWeight.w400),
              side: BorderSide(color: on ? IbColors.accent.withValues(alpha: 0.25) : IbColors.line),
              backgroundColor: IbColors.bgCard,
            );
          }),
        ),
        SectionTitleRow(
          title: '排行榜',
          marginTop: 12,
          trailing: Text('完整榜單', style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent)),
        ),
        _RankBox(onDetail: () => context.push('/detail')),
        SectionTitleRow(
          title: '猜你喜歡',
          marginTop: 8,
          trailing: Text('換一批', style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent)),
        ),
        _GuessGrid(
          onDetail: () => context.push('/detail'),
          maxWidth: math.min(420, MediaQuery.sizeOf(context).width),
        ),
        const SectionTitleRow(title: '完結經典 · 一口價', marginTop: 8),
        SizedBox(
          height: 200,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            children: [
              _HCard(2, '海風與舊信箋\n全本特惠', () => context.push('/detail'), v2: true, accentSub: true),
              _HCard(4, '霧島心事\n全本一口價', () => context.push('/detail'), accentSub: true),
              _HCard(5, '半城煙火\n全本特惠', () => context.push('/detail'), v2: true, accentSub: true),
            ],
          ),
        ),
        const HintLine('頂欄 🔍 進入搜尋頁；分類網格進入分類列表。'),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3D2A28), Color(0xFF8B3A2E)]),
            boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
                child: Text('輪播 · 編輯精選', style: GoogleFonts.notoSansTc(fontSize: 10.4, color: Colors.white)),
              ),
              const SizedBox(height: 6),
              Text(
                '長夜將盡，燈火仍為你亮著一章',
                style: GoogleFonts.notoSerifTc(fontSize: 17.9, fontWeight: FontWeight.w600, color: Colors.white, height: 1.35),
              ),
              const SizedBox(height: 4),
              Text('限時折扣 · 完結高分 · 海外繁體精校', style: GoogleFonts.notoSansTc(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.92))),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _dot(true),
                  const SizedBox(width: 5),
                  _dot(false),
                  const SizedBox(width: 5),
                  _dot(false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(bool on) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: on ? 14 : 5,
      height: 5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(99),
        color: on ? Colors.white : Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

class _HCard extends StatelessWidget {
  const _HCard(this.variant, this.label, this.onTap, {this.v2 = false, this.accentSub = false});

  final int variant;
  final String label;
  final VoidCallback onTap;
  final bool v2;
  final bool accentSub;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 132,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: BookCover(
                  variant: v2 ? 2 : variant,
                  borderRadius: 12,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text(
                  label,
                  maxLines: 3,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                    color: accentSub ? IbColors.accent : IbColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  const _WideCard({
    required this.gradient,
    required this.tag,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  final LinearGradient gradient;
  final String tag;
  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 260,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: gradient, boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 12)]),
        padding: const EdgeInsets.all(12),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
              child: Text(tag, style: GoogleFonts.notoSansTc(fontSize: 10.4, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.notoSerifTc(fontSize: 14.1, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 4),
            Text(sub, style: GoogleFonts.notoSansTc(fontSize: 10.4, color: Colors.white.withValues(alpha: 0.9))),
          ],
        ),
      ),
    );
  }
}

class _RankBox extends StatelessWidget {
  const _RankBox({required this.onDetail});

  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: IbColors.bgCard, borderRadius: BorderRadius.circular(14), boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 12)]),
      child: Column(
        children: [
          _RankRow(rank: 1, gold: true, title: '霓虹深處的約定', tail: '付費榜', cover: 1, onTap: onDetail),
          _RankRow(rank: 2, gold: true, title: '海風與舊信箋', tail: '熱度', cover: 2, onTap: onDetail),
          _RankRow(rank: 3, gold: false, title: '南洋夜雨錄', tail: '新书', cover: 3, onTap: onDetail),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.gold,
    required this.title,
    required this.tail,
    required this.cover,
    required this.onTap,
  });

  final int rank;
  final bool gold;
  final String title;
  final String tail;
  final int cover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansTc(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: gold ? IbColors.gold : IbColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 36, height: 48, child: BookCover(variant: cover, aspectRatio: 3 / 4, borderRadius: 6)),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: GoogleFonts.notoSansTc(fontSize: 13.5, fontWeight: FontWeight.w500))),
            Text(tail, style: GoogleFonts.notoSansTc(fontSize: 10.4, color: IbColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}

class _GuessGrid extends StatelessWidget {
  const _GuessGrid({required this.onDetail, required this.maxWidth});

  final VoidCallback onDetail;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final items = [
      (1, '霓虹深處的約定', '連載 · 付費閱讀', true, false),
      (2, '海風與舊信箋', '完結 · 精校', false, false),
      (3, '南洋夜雨錄', '連載 · 可購買', false, true),
      (4, '霧島心事', '懸疑', false, false),
      (5, '半城煙火', '古言', false, false),
      (6, '星塵旅人', '科幻', false, false),
    ];
    final cellW = (maxWidth - 28 - 16) / 3;
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: items.map((e) {
        return SizedBox(
          width: cellW,
          child: InkWell(
            onTap: onDetail,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    BookCover(variant: e.$1, borderRadius: 10),
                    if (e.$4)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: IbColors.accent, borderRadius: BorderRadius.circular(5)),
                          child: Text('VIP', style: GoogleFonts.notoSansTc(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    if (e.$5)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(color: IbColors.gold, borderRadius: BorderRadius.circular(5)),
                          child: Text('限免', style: GoogleFonts.notoSansTc(fontSize: 9, color: IbColors.ink, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(e.$2, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.notoSansTc(fontSize: 11.5, fontWeight: FontWeight.w500)),
                Text(e.$3, style: GoogleFonts.notoSansTc(fontSize: 9.9, color: IbColors.inkMuted)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
