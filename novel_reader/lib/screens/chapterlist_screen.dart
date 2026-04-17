import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../src/api/api_exception.dart';
import '../src/data/ibooks_repository.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';
import '../widgets/section_title_row.dart';
class ChapterListScreen extends StatefulWidget {
  const ChapterListScreen({
    super.key,
    required this.bookId,
    this.bookTitle = '',
    this.reopenReaderOnPop = false,
    this.reopenChapterId,
  });

  final int bookId;
  final String bookTitle;
  final bool reopenReaderOnPop;
  final int? reopenChapterId;

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  List<ChapterListItem>? _items;
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
      final repo = context.read<IbooksRepository>();
      final list = await repo.chaptersForBook(widget.bookId);
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _err = e.message;
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

  void _handleBack(BuildContext context) {
    context.pop();
    if (widget.reopenReaderOnPop && widget.reopenChapterId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.push('/reader/${widget.reopenChapterId}?bookId=${widget.bookId}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.bookTitle.isEmpty ? '書籍' : widget.bookTitle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) _handleBack(context);
      },
      child: IbSubpageScaffold(
        title: '目錄',
        subtitle: '章節列表',
        onBack: () => _handleBack(context),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            ),
            Text(
              '書籍 ID ${widget.bookId} · 由後端 /api/books/:id/chapters',
              style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_err != null)
              Padding(
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
            else
              ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final c in _items ?? const <ChapterListItem>[])
                    _Chap(
                      title: '第 ${c.chapterNum} 章 ${c.title}',
                      paid: !c.isFree,
                      onTap: () => context.push('/reader/${c.id}?bookId=${widget.bookId}'),
                    ),
                  if ((_items ?? []).isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('暫無章節', style: GoogleFonts.notoSansTc(color: IbColors.inkMuted)),
                    ),
                ],
              ),
            const HintLine('點章節進入閱讀器；付費章需登入並購買後由後端下發密鑰。'),
          ],
        ),
      ),
    );
  }
}

class _Chap extends StatelessWidget {
  const _Chap({required this.title, required this.paid, required this.onTap});

  final String title;
  final bool paid;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(title, style: GoogleFonts.notoSansTc(fontSize: 13.1))),
            Text(
              paid ? '🔒 付費' : '免費',
              style: GoogleFonts.notoSansTc(fontSize: 11.5, color: paid ? IbColors.gold : IbColors.inkMuted),
            ),
          ],
        ),
      ),
    );
  }
}
