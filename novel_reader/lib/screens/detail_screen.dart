import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../router/chapter_list_args.dart';
import '../src/data/ibooks_repository.dart';
import '../src/data/shelf_controller.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/book_covers.dart';
import '../widgets/ibooks_subpage_scaffold.dart';
import '../widgets/section_title_row.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  BookRow? _book;
  String? _err;
  bool _loading = true;
  bool _shelfBusy = false;

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
      final repo = context.read<IbooksRepository>();
      final b = await repo.bookDetail(widget.bookId);
      if (!mounted) return;
      setState(() {
        _book = b;
        _loading = false;
        if (b == null) _err = '書籍不存在';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleShelf() async {
    final b = _book;
    if (b == null) return;
    final shelf = context.read<ShelfController>();
    setState(() => _shelfBusy = true);
    try {
      if (shelf.contains(b.id)) {
        await shelf.remove(b.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已從書架移除')));
      } else {
        await shelf.addFromBook(b);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已加入書架')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('操作失敗：$e')));
    } finally {
      if (mounted) setState(() => _shelfBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = _book;
    final inShelf = context.watch<ShelfController>().contains(widget.bookId);

    return IbSubpageScaffold(
      title: '書籍詳情',
      subtitle: '目錄 · 試讀',
      onBack: () => context.pop(),
      body: _loading
          ? const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          : _err != null && b == null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_err!, style: GoogleFonts.notoSansTc(color: Colors.redAccent)),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _load, child: const Text('重試')),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 104,
                          child: NetworkBookCover(
                            coverUrl: b?.coverUrl,
                            borderRadius: 10,
                            aspectRatio: 3 / 4,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b?.title ?? '',
                                style: GoogleFonts.notoSerifTc(fontSize: 18, fontWeight: FontWeight.w600, height: 1.25),
                              ),
                              const SizedBox(height: 6),
                              _MetaLine([
                                if ((b?.author ?? '').isNotEmpty) '作者：${b!.author}',
                                if ((b?.category ?? '').isNotEmpty) b!.category!,
                                if ((b?.status ?? '').isNotEmpty) b!.status!,
                              ]),
                              const SizedBox(height: 8),
                              _MetaLine([
                                if ((b?.chapterCount ?? 0) > 0) '共 ${b!.chapterCount} 章',
                                if ((b?.wordCount ?? 0) > 0) '約 ${_fmtWords(b!.wordCount!)} 字',
                              ]),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SectionTitleRow(title: '簡介', marginTop: 18),
                    Text(
                      (b?.description ?? '').trim().isEmpty ? '暫無簡介' : (b?.description ?? '').trim(),
                      style: GoogleFonts.notoSansTc(fontSize: 13, height: 1.7, color: IbColors.ink),
                    ),
                    const SectionTitleRow(title: '目錄', marginTop: 18),
                    Material(
                      color: IbColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: () => context.push(
                          '/chapterlist/${widget.bookId}',
                          extra: ChapterListArgs(bookId: widget.bookId, bookTitle: b?.title ?? ''),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('查看完整目錄', style: GoogleFonts.notoSansTc(fontSize: 13.5)),
                              Text('共 ${b?.chapterCount ?? 0} 章 ›', style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
      bottom: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: IbColors.bg,
            border: Border(top: BorderSide(color: IbColors.line)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: IbColors.accent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: b == null
                        ? null
                        : () => context.push(
                              '/chapterlist/${widget.bookId}',
                              extra: ChapterListArgs(bookId: widget.bookId, bookTitle: b.title),
                            ),
                    child: Text('開始閱讀', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13)),
                    onPressed: b == null || _shelfBusy ? null : _toggleShelf,
                    child: Text(
                      inShelf ? '已加入書架' : '加入書架',
                      style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _fmtWords(int n) {
  if (n >= 10000) {
    final v = (n / 10000);
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)} 萬';
  }
  return n.toString();
}

class _MetaLine extends StatelessWidget {
  const _MetaLine(this.parts);
  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    final p = parts.where((e) => e.trim().isNotEmpty).toList();
    if (p.isEmpty) return const SizedBox.shrink();
    return Text(
      p.join(' · '),
      style: GoogleFonts.notoSansTc(fontSize: 11.8, color: IbColors.inkMuted, height: 1.45),
    );
  }
}
