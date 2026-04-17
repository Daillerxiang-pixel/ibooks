import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../router/chapter_list_args.dart';
import '../src/api/api_exception.dart';
import '../src/data/chapter_body_inline.dart';
import '../src/data/chapter_content_repository.dart';
import '../src/data/ibooks_repository.dart';
import '../src/domain/chapter_body.dart';
import '../src/domain/chapter_meta.dart';
import '../theme/ibooks_colors.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.chapterId, required this.bookId});

  final int chapterId;
  final int bookId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ChapterBody? _body;
  String? _error;
  bool _loading = true;
  List<ChapterListItem>? _toc;
  final _contentRepo = ChapterContentRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant ReaderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chapterId != widget.chapterId || oldWidget.bookId != widget.bookId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _body = null;
    });
    final repo = context.read<IbooksRepository>();
    try {
      final payload = await repo.chapterContent(widget.chapterId);
      ChapterBody body;
      if (payload.deliveryMode == 'inline') {
        final c = payload.content ?? '';
        body = chapterBodyFromInlineString(c);
      } else {
        final meta = ChapterMeta(
          id: payload.id.toString(),
          bookId: widget.bookId.toString(),
          title: payload.title,
          sortOrder: 0,
          isFree: payload.price == 0,
          contentOssUrls: payload.ossUrls ?? const [],
          contentKeyBase64: payload.contentKeyBase64,
          isEncrypted: payload.isEncrypted ?? false,
        );
        body = await _contentRepo.loadBody(meta);
      }
      if (!mounted) return;
      setState(() {
        _body = body;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      if (e.isUnauthorized && mounted) {
        _promptLogin();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _promptLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = '/reader/${widget.chapterId}?bookId=${widget.bookId}';
      context.push('/login?redirect=${Uri.encodeComponent(path)}');
    });
  }

  Future<void> _ensureToc() async {
    if (_toc != null) return;
    final repo = context.read<IbooksRepository>();
    try {
      final list = await repo.chaptersForBook(widget.bookId);
      if (mounted) setState(() => _toc = list);
    } catch (_) {}
  }

  Future<void> _goNeighbor(int delta) async {
    await _ensureToc();
    final toc = _toc;
    if (toc == null || toc.isEmpty) return;
    final i = toc.indexWhere((c) => c.id == widget.chapterId);
    if (i < 0) return;
    final j = i + delta;
    if (j < 0 || j >= toc.length) return;
    final next = toc[j];
    if (!mounted) return;
    context.go('/reader/${next.id}?bookId=${widget.bookId}');
  }

  void _openToc(BuildContext context) {
    final router = GoRouter.of(context);
    router.pop();
    router.push(
      '/chapterlist/${widget.bookId}',
      extra: ChapterListArgs(
        bookId: widget.bookId,
        reopenReader: true,
        reopenChapterId: widget.chapterId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _body?.title.isNotEmpty == true ? _body!.title : '閱讀';

    return Scaffold(
      backgroundColor: IbColors.readerBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text('‹ 返回', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 14)),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 14.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _openToc(context),
                    child: Text('目錄', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 11.5)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(color: IbColors.readerFg)),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _load,
                                  child: const Text('重試'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: DefaultTextStyle(
                            style: GoogleFonts.notoSansTc(
                              fontSize: 17,
                              height: 1.95,
                              color: IbColors.readerFg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final p in _body?.paragraphs ?? const <String>[]) ...[
                                  Text(p),
                                  const SizedBox(height: 20),
                                ],
                              ],
                            ),
                          ),
                        ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              decoration: BoxDecoration(color: IbColors.readerBg.withValues(alpha: 0.96), border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => _goNeighbor(-1),
                    child: Text('上一章', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 12.5)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('閱讀設定', style: GoogleFonts.notoSansTc(color: const Color(0xFFF0D78C), fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text('日／夜', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 12.5)),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => _goNeighbor(1),
                    child: Text('下一章', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 12.5)),
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
