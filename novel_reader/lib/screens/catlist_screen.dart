import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../src/data/ibooks_repository.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/book_covers.dart';
import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';
import '../widgets/section_title_row.dart';

/// 按分類列表：拉 `/api/books`，按 `category == categoryName` 過濾。
class CatlistScreen extends StatefulWidget {
  const CatlistScreen({super.key, required this.categoryName});

  final String categoryName;

  @override
  State<CatlistScreen> createState() => _CatlistScreenState();
}

enum _SortKey { hot, chapters, words, recent }

class _CatlistScreenState extends State<CatlistScreen> {
  _SortKey _sort = _SortKey.hot;
  List<BookRow>? _all;
  String? _err;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await context.read<IbooksRepository>().listBooks();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  List<BookRow> _filteredSorted() {
    final src = (_all ?? []).where((b) {
      if (widget.categoryName == '全部') return true;
      return (b.category ?? '').trim() == widget.categoryName;
    }).toList();
    switch (_sort) {
      case _SortKey.hot:
      case _SortKey.chapters:
        src.sort((a, b) => (b.chapterCount ?? 0).compareTo(a.chapterCount ?? 0));
        break;
      case _SortKey.words:
        src.sort((a, b) => (b.wordCount ?? 0).compareTo(a.wordCount ?? 0));
        break;
      case _SortKey.recent:
        src.sort((a, b) => b.id.compareTo(a.id)); // 沒有 created_at 字段，按 id 倒序近似最新
        break;
    }
    return src;
  }

  String _sortLabel(_SortKey k) {
    switch (k) {
      case _SortKey.hot:
        return '熱門';
      case _SortKey.chapters:
        return '章節數';
      case _SortKey.words:
        return '字數';
      case _SortKey.recent:
        return '最新';
    }
  }

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: widget.categoryName == '全部' ? '全部分類' : widget.categoryName,
      subtitle: '排序篩選',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '排序方式',
            style: GoogleFonts.notoSansTc(
              fontSize: 10.9,
              color: IbColors.inkMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final k in _SortKey.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(_sortLabel(k),
                          style: GoogleFonts.notoSansTc(fontSize: 11.5)),
                      selected: k == _sort,
                      onSelected: (_) => setState(() => _sort = k),
                      selectedColor: IbColors.accentSoft,
                      backgroundColor: IbColors.bgCard,
                    ),
                  ),
              ],
            ),
          ),
          if (_loading && _all == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_err != null && (_all == null || _all!.isEmpty))
            ErrorState(message: '加載失敗：\n$_err', onRetry: _load)
          else
            _buildList(),
        ],
      ),
    );
  }

  Widget _buildList() {
    final list = _filteredSorted();
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            '此分類下暫無書籍',
            style: TextStyle(color: IbColors.inkMuted),
          ),
        ),
      );
    }
    return Column(
      children: [
        SectionTitleRow(title: '${widget.categoryName} · 共 ${list.length} 本', marginTop: 14),
        for (var i = 0; i < list.length; i++)
          _BookRow(rank: i + 1, book: list[i], onTap: () => context.push('/detail/${list[i].id}')),
      ],
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.rank, required this.book, required this.onTap});
  final int rank;
  final BookRow book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSansTc(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3 ? IbColors.gold : IbColors.inkMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 48,
              height: 64,
              child: NetworkBookCover(
                coverUrl: book.coverUrl,
                borderRadius: 6,
                aspectRatio: 3 / 4,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 14.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if ((book.author ?? '').isNotEmpty) book.author!,
                      if ((book.category ?? '').isNotEmpty) book.category!,
                      if ((book.status ?? '').isNotEmpty) book.status!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 11.2,
                      color: IbColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${book.chapterCount ?? 0} 章',
              style: GoogleFonts.notoSansTc(
                fontSize: 11,
                color: IbColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
