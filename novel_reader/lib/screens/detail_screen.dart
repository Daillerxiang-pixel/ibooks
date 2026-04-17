import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../router/chapter_list_args.dart';
import '../src/data/ibooks_repository.dart';
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

  @override
  Widget build(BuildContext context) {
    final b = _book;

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
                          child: AppConfig.resolvePublicUrl(b?.coverUrl) != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: AspectRatio(
                                    aspectRatio: 3 / 4,
                                    child: Image.network(
                                      AppConfig.resolvePublicUrl(b!.coverUrl)!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const BookCover(variant: 1, borderRadius: 10),
                                    ),
                                  ),
                                )
                              : const BookCover(variant: 1, borderRadius: 10),
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
                              Text(
                                '${b?.author ?? '未知作者'} · ${b?.category ?? ''} · ${b?.status ?? ''}',
                                style: GoogleFonts.notoSansTc(fontSize: 11.8, color: IbColors.inkMuted, height: 1.45),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '共 ${b?.chapterCount ?? 0} 章 · 約 ${b?.wordCount ?? 0} 字',
                                style: GoogleFonts.notoSansTc(fontSize: 12.2, color: IbColors.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (b?.description ?? '').trim().isEmpty ? '暫無簡介' : (b?.description ?? '').trim(),
                      style: GoogleFonts.notoSansTc(fontSize: 12.8, height: 1.65, color: IbColors.inkMuted),
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
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: IbColors.accent, padding: const EdgeInsets.symmetric(vertical: 13)),
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
