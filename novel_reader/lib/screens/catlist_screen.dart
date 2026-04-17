import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/book_covers.dart';
import '../widgets/ibooks_subpage_scaffold.dart';
import '../widgets/section_title_row.dart';

class CatlistScreen extends StatefulWidget {
  const CatlistScreen({super.key, required this.categoryName});

  final String categoryName;

  @override
  State<CatlistScreen> createState() => _CatlistScreenState();
}

class _CatlistScreenState extends State<CatlistScreen> {
  int _sort = 0;
  final _sortLabels = const ['綜合熱門', '付費／暢銷', '收藏', '字數', '最近更新'];

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryName == '全部' ? '全部 · 作品列表' : '${widget.categoryName} · 作品列表';
    return IbSubpageScaffold(
      title: widget.categoryName == '全部' ? '全部分類' : widget.categoryName,
      subtitle: '排序篩選',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('排序方式', style: GoogleFonts.notoSansTc(fontSize: 10.9, color: IbColors.inkMuted, letterSpacing: 0.6)),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(_sortLabels.length, (i) {
                final on = i == _sort;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(_sortLabels[i], style: GoogleFonts.notoSansTc(fontSize: 11.5)),
                    selected: on,
                    onSelected: (_) => setState(() => _sort = i),
                    selectedColor: IbColors.accentSoft,
                    labelStyle: TextStyle(color: on ? IbColors.accent : IbColors.inkMuted, fontWeight: on ? FontWeight.w600 : FontWeight.w400),
                    side: BorderSide(color: on ? IbColors.accent.withOpacity(0.35) : IbColors.line),
                    backgroundColor: IbColors.bgCard,
                  ),
                );
              }),
            ),
          ),
          SectionTitleRow(title: title, marginTop: 14),
          _RankRow(n: 1, badge: _Badge.gold, title: '霓虹深處的約定', sub: '連載 · 128 萬字 · 都市言情', stat: '熱銷指數 98', cover: 1, onTap: () => context.push('/detail')),
          _RankRow(n: 2, badge: _Badge.silver, title: '海風與舊信箋', sub: '完結 · 付費精校', stat: '熱銷 92', cover: 2, onTap: () => context.push('/detail')),
          _RankRow(n: 3, badge: _Badge.bronze, title: '南洋夜雨錄', sub: '連載 · 海外繁體', stat: '熱銷 88', cover: 3, onTap: () => context.push('/detail')),
          _RankRow(n: 4, badge: _Badge.plain, title: '霧島心事', sub: '懸疑 · 熱度攀升', stat: '熱銷 81', cover: 4, onTap: () => context.push('/detail')),
          const HintLine('原型：排序切換會更新右側統計文案；正式版對接 API query。'),
        ],
      ),
    );
  }
}

enum _Badge { gold, silver, bronze, plain }

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.n,
    required this.badge,
    required this.title,
    required this.sub,
    required this.stat,
    required this.cover,
    required this.onTap,
  });

  final int n;
  final _Badge badge;
  final String title;
  final String sub;
  final String stat;
  final int cover;
  final VoidCallback onTap;

  Color get _badgeColor {
    switch (badge) {
      case _Badge.gold:
        return IbColors.gold;
      case _Badge.silver:
        return const Color(0xFFB0B0B0);
      case _Badge.bronze:
        return const Color(0xFFCD853F);
      case _Badge.plain:
        return IbColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 24,
              alignment: Alignment.center,
              child: Text(
                '$n',
                style: GoogleFonts.notoSansTc(fontSize: 13, fontWeight: FontWeight.w800, color: _badgeColor),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 40, height: 54, child: BookCover(variant: cover, aspectRatio: 3 / 4, borderRadius: 6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.notoSansTc(fontSize: 14.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Text(sub, style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
                ],
              ),
            ),
            Text(stat, style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
          ],
        ),
      ),
    );
  }
}
