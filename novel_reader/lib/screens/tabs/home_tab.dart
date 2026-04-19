import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../src/data/ibooks_repository.dart';
import '../../theme/ibooks_colors.dart';
import '../../widgets/book_covers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_title_row.dart';

/// 書城首頁：全部從 `/api/books` 拉取，本地不再寫死任何書名/封面。
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<BookRow>? _books;
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
        _books = list;
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

  // ---------- 衍生視圖數據（基於同一份 _books 列表） ----------

  /// 推薦列表：按章節數倒序前 12 本
  List<BookRow> get _featured {
    final list = [...?_books];
    list.sort((a, b) => (b.chapterCount ?? 0).compareTo(a.chapterCount ?? 0));
    return list.take(12).toList();
  }

  /// 排行榜：取章節數最高的前 5 本
  List<BookRow> get _ranking {
    final list = [...?_books];
    list.sort((a, b) => (b.chapterCount ?? 0).compareTo(a.chapterCount ?? 0));
    return list.take(5).toList();
  }

  /// 完結 / 一口價：status == '完结' 或 '完結'
  List<BookRow> get _finished {
    return (_books ?? []).where((b) {
      final s = (b.status ?? '').trim();
      return s.contains('完结') || s.contains('完結') || s == 'finished';
    }).take(8).toList();
  }

  /// 熱門分類：對所有書的 category 字段去重
  List<String> get _categories {
    final set = <String>{};
    for (final b in (_books ?? [])) {
      final c = (b.category ?? '').trim();
      if (c.isNotEmpty) set.add(c);
    }
    return set.toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _books == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_err != null && (_books == null || _books!.isEmpty)) {
      return ErrorState(message: '加載書城失敗：\n$_err', onRetry: _load);
    }
    final books = _books ?? [];
    if (books.isEmpty) {
      return const ErrorState(
        icon: Icons.menu_book_outlined,
        message: '書城暫無上架書籍\n請先在後端入庫',
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _SectionFeatured(
              books: books.take(4).toList(),
              onTap: (id) => context.push('/detail/$id'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: SectionTitleRow(
              title: '本週推薦',
              marginTop: 0,
              trailing: Text('${_featured.length} 本',
                  style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent)),
            ),
          ),
          SizedBox(
            height: 210,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                for (final b in _featured)
                  _BookHCard(book: b, onTap: () => context.push('/detail/${b.id}')),
              ],
            ),
          ),
          if (_categories.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: SectionTitleRow(title: '熱門分類', marginTop: 0),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in _categories)
                    InputChip(
                      label: Text(c, style: GoogleFonts.notoSansTc(fontSize: 11.5)),
                      onPressed: () =>
                          context.push('/catlist?cat=${Uri.encodeQueryComponent(c)}'),
                      backgroundColor: IbColors.bgCard,
                      side: const BorderSide(color: IbColors.line),
                    ),
                ],
              ),
            ),
          ],
          if (_ranking.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: SectionTitleRow(title: '排行榜', marginTop: 0),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _RankList(
                books: _ranking,
                onTap: (id) => context.push('/detail/$id'),
              ),
            ),
          ],
          if (_finished.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: SectionTitleRow(title: '完結作品', marginTop: 0),
            ),
            SizedBox(
              height: 210,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                children: [
                  for (final b in _finished)
                    _BookHCard(book: b, onTap: () => context.push('/detail/${b.id}')),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionFeatured extends StatelessWidget {
  const _SectionFeatured({required this.books, required this.onTap});
  final List<BookRow> books;
  final void Function(int bookId) onTap;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    final first = books.first;
    return InkWell(
      onTap: () => onTap(first.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3D2A28), Color(0xFF8B3A2E)],
            ),
            boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 16, offset: Offset(0, 8))],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 64,
                child: NetworkBookCover(
                  coverUrl: first.coverUrl,
                  borderRadius: 8,
                  aspectRatio: 3 / 4,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(99)),
                      child: Text(
                        '編輯精選',
                        style: GoogleFonts.notoSansTc(fontSize: 10.4, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      first.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerifTc(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        if ((first.author ?? '').isNotEmpty) first.author!,
                        if ((first.category ?? '').isNotEmpty) first.category!,
                      ].join(' · '),
                      style: GoogleFonts.notoSansTc(
                        fontSize: 11.5,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookHCard extends StatelessWidget {
  const _BookHCard({required this.book, required this.onTap});
  final BookRow book;
  final VoidCallback onTap;

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
                child: NetworkBookCover(
                  coverUrl: book.coverUrl,
                  borderRadius: 12,
                  aspectRatio: 3 / 4,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
                child: Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansTc(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              if ((book.author ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 2, top: 2),
                  child: Text(
                    book.author!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.notoSansTc(
                      fontSize: 10,
                      color: IbColors.inkMuted,
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

class _RankList extends StatelessWidget {
  const _RankList({required this.books, required this.onTap});
  final List<BookRow> books;
  final void Function(int bookId) onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: IbColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 12)],
      ),
      child: Column(
        children: [
          for (var i = 0; i < books.length; i++)
            _RankRow(
              rank: i + 1,
              book: books[i],
              onTap: () => onTap(books[i].id),
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.book, required this.onTap});
  final int rank;
  final BookRow book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final goldColor = rank <= 3 ? IbColors.gold : IbColors.inkMuted;
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
                  color: goldColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              height: 48,
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
                    style: GoogleFonts.notoSansTc(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  if ((book.author ?? '').isNotEmpty)
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansTc(
                        fontSize: 10.5,
                        color: IbColors.inkMuted,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${book.chapterCount ?? 0} 章',
              style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
