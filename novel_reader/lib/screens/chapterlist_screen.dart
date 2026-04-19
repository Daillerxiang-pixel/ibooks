import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../src/api/api_exception.dart';
import '../src/data/ibooks_repository.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

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
        subtitle: title,
        onBack: () => _handleBack(context),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_items != null && _items!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '共 ${_items!.length} 章',
                  style: GoogleFonts.notoSansTc(
                      fontSize: 11.5, color: IbColors.inkMuted),
                ),
              ),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: IbColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.notoSansTc(fontSize: 13.5),
              ),
            ),
            const SizedBox(width: 8),
            if (paid)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 13, color: IbColors.gold),
                  const SizedBox(width: 4),
                  Text(
                    '付費',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 11.2,
                      color: IbColors.gold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Text(
                '免費',
                style: GoogleFonts.notoSansTc(
                  fontSize: 11.2,
                  color: IbColors.inkMuted,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 18, color: IbColors.inkMuted.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}
