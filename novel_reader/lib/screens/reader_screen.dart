import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../router/chapter_list_args.dart';
import '../src/api/api_exception.dart';
import '../src/data/chapter_body_inline.dart';
import '../src/data/chapter_content_repository.dart';
import '../src/data/ibooks_repository.dart';
import '../src/data/reader_settings.dart';
import '../src/domain/chapter_body.dart';
import '../src/domain/chapter_meta.dart';
import '../theme/app_layout.dart';
import '../widgets/reader_settings_sheet.dart';

/// 沉浸式閱讀器：
/// - 預設 **隱藏所有控件**（頂部/底部欄）；
/// - 點擊正文 **中間 1/3 區** 顯示/隱藏控件；
/// - 點擊左 1/3 翻上一頁（一個視窗向上滾動），右 1/3 翻下一頁；
/// - 完全持久化 [ReaderSettings]：字號、行距、主題（含夜間）、字體。
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
  bool _chromeVisible = false;
  final _contentRepo = ChapterContentRepository();
  final _scrollCtrl = ScrollController();

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

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _body = null;
      _chromeVisible = false;
    });
    final repo = context.read<IbooksRepository>();
    try {
      final payload = await repo.chapterContent(widget.chapterId);
      ChapterBody body;
      if (payload.deliveryMode == 'inline') {
        body = chapterBodyFromInlineString(payload.content ?? '');
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      if (e.isUnauthorized && mounted) _promptLogin();
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

  void _onTapContent(TapUpDetails d, double width, double height) {
    final dx = d.localPosition.dx;
    final dy = d.localPosition.dy;
    // 中間 60% 寬 + 中間 50% 高 -> 切換控件顯示
    final inMidX = dx > width * 0.2 && dx < width * 0.8;
    final inMidY = dy > height * 0.25 && dy < height * 0.75;
    if (inMidX && inMidY) {
      HapticFeedback.selectionClick();
      setState(() => _chromeVisible = !_chromeVisible);
      return;
    }
    // 隱藏控件時左右點擊：上下翻一屏
    if (!_chromeVisible && _scrollCtrl.hasClients) {
      final delta = height * 0.85;
      final target = _scrollCtrl.offset + (dx < width * 0.5 ? -delta : delta);
      final clamped = target.clamp(0.0, _scrollCtrl.position.maxScrollExtent);
      _scrollCtrl.animateTo(
        clamped,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettings>();
    final theme = settings.theme;
    final fg = theme.fg;
    final title = _body?.title.isNotEmpty == true ? _body!.title : '閱讀';

    final baseTextStyle = (settings.family == ReaderFontFamily.serif
            ? GoogleFonts.notoSerifTc
            : GoogleFonts.notoSansTc)(
      fontSize: settings.fontSize,
      height: settings.lineHeight,
      color: fg,
    );

    return Scaffold(
      backgroundColor: theme.bg,
      body: Stack(
        children: [
          // 正文層
          Positioned.fill(
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, c) {
                  final maxW = math.min(
                    AppLayout.contentMaxWidth + 20,
                    c.maxWidth - AppLayout.screenGutter * 2,
                  );
                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (d) => _onTapContent(d, c.maxWidth, c.maxHeight),
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : _error != null
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(_error!, textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(color: fg)),
                                          const SizedBox(height: 16),
                                          FilledButton(onPressed: _load, child: const Text('重試')),
                                        ],
                                      ),
                                    ),
                                  )
                                : _ChapterContent(
                                    title: title,
                                    body: _body!,
                                    baseStyle: baseTextStyle,
                                    fg: fg,
                                    scrollCtrl: _scrollCtrl,
                                    topPad: 56,
                                    bottomPad: 64,
                                  ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 頂部控件條
          AnimatedSlide(
            offset: Offset(0, _chromeVisible ? 0 : -1),
            duration: const Duration(milliseconds: 220),
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Material(
                color: theme.chromeBg,
                elevation: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: '返回',
                          icon: Icon(Icons.arrow_back, color: fg),
                          onPressed: () => context.pop(),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansTc(color: fg, fontSize: 14.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: '目錄',
                          icon: Icon(Icons.menu_book_outlined, color: fg),
                          onPressed: () => _openToc(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 底部控件條
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: Offset(0, _chromeVisible ? 0 : 1),
              duration: const Duration(milliseconds: 220),
              child: AnimatedOpacity(
                opacity: _chromeVisible ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Material(
                  color: theme.chromeBg,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _BottomBtn(
                            icon: Icons.skip_previous,
                            label: '上一章',
                            fg: fg,
                            onTap: _loading ? null : () => _goNeighbor(-1),
                          ),
                          _BottomBtn(
                            icon: settings.theme == ReaderTheme.dark ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                            label: settings.theme == ReaderTheme.dark ? '日間' : '夜間',
                            fg: fg,
                            onTap: () => settings.toggleDayNight(),
                          ),
                          _BottomBtn(
                            icon: Icons.format_size,
                            label: '閱讀設定',
                            fg: fg,
                            onTap: () => ReaderSettingsSheet.show(context),
                          ),
                          _BottomBtn(
                            icon: Icons.skip_next,
                            label: '下一章',
                            fg: fg,
                            onTap: _loading ? null : () => _goNeighbor(1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChapterContent extends StatelessWidget {
  const _ChapterContent({
    required this.title,
    required this.body,
    required this.baseStyle,
    required this.fg,
    required this.scrollCtrl,
    required this.topPad,
    required this.bottomPad,
  });

  final String title;
  final ChapterBody body;
  final TextStyle baseStyle;
  final Color fg;
  final ScrollController scrollCtrl;
  final double topPad;
  final double bottomPad;

  @override
  Widget build(BuildContext context) {
    final paragraphSpacing = baseStyle.fontSize! * 0.85;
    final titleStyle = GoogleFonts.notoSerifTc(
      fontSize: baseStyle.fontSize! + 4,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: fg,
    );

    return ListView(
      controller: scrollCtrl,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, topPad, 20, bottomPad),
      children: [
        if (title.isNotEmpty) ...[
          Text(title, style: titleStyle),
          SizedBox(height: paragraphSpacing * 1.6),
        ],
        for (final p in body.paragraphs) ...[
          Text(
            // **首行縮進兩個全角空格**（中文閱讀器常用做法）
            '\u3000\u3000${p.trim()}',
            style: baseStyle,
            textAlign: TextAlign.justify,
            strutStyle: StrutStyle(
              fontSize: baseStyle.fontSize,
              height: baseStyle.height,
              forceStrutHeight: true,
            ),
          ),
          SizedBox(height: paragraphSpacing),
        ],
        SizedBox(height: paragraphSpacing * 2),
      ],
    );
  }
}

class _BottomBtn extends StatelessWidget {
  const _BottomBtn({
    required this.icon,
    required this.label,
    required this.fg,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? fg.withOpacity(0.4) : fg;
    return InkResponse(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.notoSansTc(fontSize: 10.8, color: color)),
          ],
        ),
      ),
    );
  }
}
