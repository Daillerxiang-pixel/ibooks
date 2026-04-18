import 'dart:async';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
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
import '../src/data/shelf_controller.dart';
import '../src/domain/chapter_body.dart';
import '../src/domain/chapter_meta.dart';
import '../src/data/reading_progress_store.dart';
import '../src/reader/chapter_layout.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/reader_settings_sheet.dart';

// ─────────────────────────── 常量 ───────────────────────────
/// 頁面頂部「章節 / 書名」狀態欄佔用高度
const double _kPageHeaderH = 18.0;
/// 頂部狀態欄與正文之間的間隔
const double _kPageHeaderGap = 14.0;
/// 正文與底部狀態欄之間的間隔
const double _kPageFooterGap = 6.0;
/// 頁底「頁碼 / 時間 / 電量」狀態欄佔用高度
const double _kStatusBarH = 18.0;
/// 頁面頂部到正文起點的總高度（向下兼容原 _kPagePadTop）
const double _kPagePadTop = _kPageHeaderH + _kPageHeaderGap;

/// 沉浸式閱讀器 v2
///   - 翻頁手勢：左 1/3 上一頁，右 1/3 下一頁，中央切換 chrome
///   - 常駐底部狀態欄：章節進度 + 當前時間（分頁模式）
///   - Chrome：頂部返回/標題/書架；底部進度滑桿 + 5 按鈕列
///   - 亮度覆蓋層（半透明遮罩）
///   - 章節快取 + 預載入鄰章
class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.chapterId,
    required this.bookId,
  });

  final int chapterId;
  final int bookId;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ChapterBody? _body;
  String? _error;
  bool _loading = true;
  bool _switching = false;
  List<ChapterListItem>? _toc;
  bool _chromeVisible = false;

  /// 從後端取的書名，用於頁面頂部右上角顯示
  String? _bookTitle;

  /// 分頁模式下的當前頁（0-based），用於底部進度滑桿同步
  int _currentPage = 0;
  int _totalPages = 1;

  /// 啟動時從 [ReadingProgressStore] 取出的「上次閱讀位置」，
  /// 章節加載完成後傳給 [_PageReader] / [_ScrollReader] 用作初始頁/初始滾動。
  int? _initialPageIndex;
  double? _initialScrollOffset;

  ReaderSettings? _settingsRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsRef = context.read<ReaderSettings>();
      _settingsRef!.addListener(_applyKeepScreenOn);
      _applyKeepScreenOn();
      _load();
    });
  }

  @override
  void dispose() {
    _settingsRef?.removeListener(_applyKeepScreenOn);
    // 離開閱讀器時禁用屏幕常亮
    WakelockPlus.disable();
    // 立即落盤未保存的進度
    ReadingProgressStore.instance.flush();
    _pageTurnNotifier.dispose();
    super.dispose();
  }

  void _applyKeepScreenOn() {
    final on = _settingsRef?.keepScreenOn ?? true;
    if (on) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  @override
  void didUpdateWidget(covariant ReaderScreen old) {
    super.didUpdateWidget(old);
    if (old.chapterId != widget.chapterId || old.bookId != widget.bookId) {
      _load();
    }
  }

  // ─────────────────── 章節加載 ───────────────────

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _body = null;
      _chromeVisible = false;
      _currentPage = 0;
      _totalPages = 1;
      _initialPageIndex = null;
      _initialScrollOffset = null;
    });
    // 嘗試恢復進度（同章節才恢復）
    final saved = await ReadingProgressStore.instance.load(widget.bookId);
    if (saved != null && saved.chapterId == widget.chapterId) {
      _initialPageIndex = saved.pageIndex;
      _initialScrollOffset = saved.scrollOffset;
    }
    if (!mounted) return;
    final repo = context.read<IbooksRepository>();
    final contentRepo = context.read<ChapterContentRepository>();
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
        body = await contentRepo.loadBody(meta);
      }
      if (!mounted) return;
      setState(() {
        _body = body;
        _loading = false;
      });
      // 預載入鄰章（fire-and-forget）
      _prefetchNeighbors();
      // 拉取書名（頂部右上角顯示，僅取一次）
      if (_bookTitle == null) _fetchBookTitle();
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

  Future<void> _fetchBookTitle() async {
    try {
      final repo = context.read<IbooksRepository>();
      final b = await repo.bookDetail(widget.bookId);
      if (mounted && b != null) {
        setState(() => _bookTitle = b.title);
      }
    } catch (_) {/* 忽略；頂部書名留空即可 */}
  }

  Future<void> _prefetchNeighbors() async {
    final toc = await _ensureToc();
    if (toc == null || !mounted) return;
    final i = toc.indexWhere((c) => c.id == widget.chapterId);
    if (i < 0) return;
    final contentRepo = context.read<ChapterContentRepository>();
    final repo = context.read<IbooksRepository>();
    for (final delta in [1, -1]) {
      final j = i + delta;
      if (j < 0 || j >= toc.length) continue;
      final neighbor = toc[j];
      // 只預載 OSS 章節，inline 章節在 chapterContent 時直接返回
      try {
        final payload = await repo.chapterContent(neighbor.id);
        if (payload.deliveryMode != 'inline' && mounted) {
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
          contentRepo.prefetch(meta);
        }
      } catch (_) {}
    }
  }

  void _promptLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = '/reader/${widget.chapterId}?bookId=${widget.bookId}';
      context.push('/login?redirect=${Uri.encodeComponent(path)}');
    });
  }

  // ─────────────────── 目錄 / 章節導航 ───────────────────

  Future<List<ChapterListItem>?> _ensureToc() async {
    if (_toc != null) return _toc;
    final repo = context.read<IbooksRepository>();
    try {
      final list = await repo.chaptersForBook(widget.bookId);
      if (mounted) setState(() => _toc = list);
      return list;
    } catch (_) {
      return null;
    }
  }

  Future<void> _goNeighbor(int delta) async {
    if (_switching) return;
    _switching = true;
    try {
      final toc = await _ensureToc();
      if (toc == null || toc.isEmpty) return;
      final i = toc.indexWhere((c) => c.id == widget.chapterId);
      if (i < 0) return;
      final j = i + delta;
      if (j < 0) {
        _toast('已是第一章');
        return;
      }
      if (j >= toc.length) {
        _toast('已是最後一章');
        return;
      }
      if (!mounted) return;
      HapticFeedback.lightImpact();
      context.go('/reader/${toc[j].id}?bookId=${widget.bookId}');
    } finally {
      _switching = false;
    }
  }

  bool _hasPrev() {
    final toc = _toc;
    if (toc == null) return true; // unknown, allow attempt
    final i = toc.indexWhere((c) => c.id == widget.chapterId);
    return i > 0;
  }

  bool _hasNext() {
    final toc = _toc;
    if (toc == null) return true;
    final i = toc.indexWhere((c) => c.id == widget.chapterId);
    return i >= 0 && i < toc.length - 1;
  }

  void _toast(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), duration: const Duration(seconds: 1)),
    );
  }

  void _openToc() {
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

  // ─────────────────── Chrome 互動 ───────────────────

  void _handleTap(TapUpDetails d, double w, double h, PageTurnMode mode) {
    final dx = d.localPosition.dx;
    final dy = d.localPosition.dy;

    // 分頁模式：左 1/3 上一頁，右 1/3 下一頁，中 1/3 切換 chrome
    if (mode != PageTurnMode.scroll) {
      if (dx < w * 0.3) {
        if (_chromeVisible) {
          setState(() => _chromeVisible = false);
        } else {
          _pageTurnNotifier.value = -1;
        }
        return;
      }
      if (dx > w * 0.7) {
        if (_chromeVisible) {
          setState(() => _chromeVisible = false);
        } else {
          _pageTurnNotifier.value = 1;
        }
        return;
      }
    }

    // 中央區域：切換 chrome（所有模式）
    final inMidY = dy > h * 0.2 && dy < h * 0.8;
    if (inMidY) {
      HapticFeedback.selectionClick();
      setState(() => _chromeVisible = !_chromeVisible);
    }
  }

  // 通知 _PageReader 翻頁（+1 / -1）
  final ValueNotifier<int> _pageTurnNotifier = ValueNotifier(0);

  // ─────────────────── Build ───────────────────

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: theme.bg,
        body: Stack(
          children: [
            // ── 正文 ──
            Positioned.fill(
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, c) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) =>
                          _handleTap(d, c.maxWidth, c.maxHeight, settings.pageMode),
                      child: _loading
                          ? Center(
                              child: CircularProgressIndicator(
                                color: fg.withOpacity(0.5),
                              ),
                            )
                          : _error != null
                              ? _ErrorView(
                                  message: _error!,
                                  fg: fg,
                                  onRetry: _load,
                                )
                              : _ReaderBody(
                                  key: ValueKey(
                                    '${widget.chapterId}'
                                    '_${settings.pageMode.name}'
                                    '_${settings.fontSize.toInt()}'
                                    '_${settings.lineSpacing.name}'
                                    '_${settings.family.name}',
                                  ),
                                  chapter: _body!,
                                  settings: settings,
                                  baseStyle: baseTextStyle,
                                  pageTurnNotifier: _pageTurnNotifier,
                                  onPrev: () => _goNeighbor(-1),
                                  onNext: () => _goNeighbor(1),
                                  initialPageIndex: _initialPageIndex,
                                  initialScrollOffset: _initialScrollOffset,
                                  bookTitle: _bookTitle ?? '',
                                  chapterTitle: _body?.title ?? '',
                                  onPageChanged: (page, total) {
                                    if (_currentPage != page || _totalPages != total) {
                                      setState(() {
                                        _currentPage = page;
                                        _totalPages = total;
                                      });
                                    }
                                    // 持久化進度
                                    ReadingProgressStore.instance.save(
                                      widget.bookId,
                                      ReadingProgress(
                                        chapterId: widget.chapterId,
                                        pageIndex: page,
                                        totalPages: total,
                                        scrollOffset: 0,
                                        updatedAt: DateTime.now(),
                                      ),
                                    );
                                  },
                                ),
                    );
                  },
                ),
              ),
            ),

            // ── 亮度遮罩（始終渲染，亮度=1 時透明） ──
            if (settings.brightness < 1.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Colors.black.withOpacity(1.0 - settings.brightness),
                  ),
                ),
              ),

            // ── 頂部 Chrome ──
            IgnorePointer(
              ignoring: !_chromeVisible,
              child: AnimatedSlide(
                offset: Offset(0, _chromeVisible ? 0 : -1),
                duration: const Duration(milliseconds: 220),
                child: AnimatedOpacity(
                  opacity: _chromeVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Material(
                    color: theme.chromeBg,
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
                                style: GoogleFonts.notoSansTc(
                                  color: fg,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            _ShelfToggleButton(bookId: widget.bookId, fg: fg),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── 底部 Chrome ──
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                ignoring: !_chromeVisible,
                child: AnimatedSlide(
                  offset: Offset(0, _chromeVisible ? 0 : 1),
                  duration: const Duration(milliseconds: 220),
                  child: AnimatedOpacity(
                    opacity: _chromeVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: _BottomChrome(
                      settings: settings,
                      fg: fg,
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      hasPrev: _hasPrev(),
                      hasNext: _hasNext(),
                      onPrevChapter: () => _goNeighbor(-1),
                      onNextChapter: () => _goNeighbor(1),
                      onToc: _openToc,
                      onSettings: () => ReaderSettingsSheet.show(context),
                      onPageJump: (page) {
                        setState(() => _currentPage = page);
                        _pageTurnNotifier.value = page - _currentPage;
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── 底部 Chrome ───────────────────────────

class _BottomChrome extends StatelessWidget {
  const _BottomChrome({
    required this.settings,
    required this.fg,
    required this.currentPage,
    required this.totalPages,
    required this.hasPrev,
    required this.hasNext,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onToc,
    required this.onSettings,
    required this.onPageJump,
  });

  final ReaderSettings settings;
  final Color fg;
  final int currentPage;
  final int totalPages;
  final bool hasPrev;
  final bool hasNext;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final VoidCallback onToc;
  final VoidCallback onSettings;
  final void Function(int page) onPageJump;

  @override
  Widget build(BuildContext context) {
    final subtle = settings.theme.subtle;
    final isPageMode = settings.pageMode != PageTurnMode.scroll;
    final progressRatio =
        totalPages <= 1 ? 0.0 : currentPage / (totalPages - 1).toDouble();

    return Material(
      color: settings.theme.chromeBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 進度滑桿（僅分頁模式顯示）
              if (isPageMode && totalPages > 1) ...[
                Row(
                  children: [
                    Text(
                      '${currentPage + 1}',
                      style: GoogleFonts.notoSansTc(fontSize: 11, color: subtle),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: fg.withOpacity(0.7),
                          inactiveTrackColor: fg.withOpacity(0.15),
                          thumbColor: fg,
                          overlayColor: fg.withOpacity(0.1),
                        ),
                        child: Slider(
                          value: progressRatio.clamp(0.0, 1.0),
                          onChanged: (v) {
                            final page = (v * (totalPages - 1)).round();
                            onPageJump(page);
                          },
                        ),
                      ),
                    ),
                    Text(
                      '$totalPages',
                      style: GoogleFonts.notoSansTc(fontSize: 11, color: subtle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              // 亮度滑桿
              Row(
                children: [
                  Icon(Icons.brightness_low, size: 16, color: subtle),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                        activeTrackColor: fg.withOpacity(0.7),
                        inactiveTrackColor: fg.withOpacity(0.15),
                        thumbColor: fg,
                        overlayColor: fg.withOpacity(0.1),
                      ),
                      child: Slider(
                        value: settings.brightness,
                        min: 0.2,
                        max: 1.0,
                        onChanged: settings.setBrightness,
                      ),
                    ),
                  ),
                  Icon(Icons.brightness_high, size: 16, color: subtle),
                ],
              ),
              const SizedBox(height: 4),

              // 五按鈕列
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ChromeBtn(
                    icon: Icons.skip_previous_outlined,
                    label: '上一章',
                    fg: hasPrev ? fg : fg.withOpacity(0.3),
                    onTap: hasPrev ? onPrevChapter : null,
                  ),
                  _ChromeBtn(
                    icon: Icons.menu_book_outlined,
                    label: '目錄',
                    fg: fg,
                    onTap: onToc,
                  ),
                  _ChromeBtn(
                    icon: settings.theme == ReaderTheme.dark
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined,
                    label: settings.theme == ReaderTheme.dark ? '日間' : '夜間',
                    fg: fg,
                    onTap: () => settings.toggleDayNight(),
                  ),
                  _ChromeBtn(
                    icon: Icons.format_size,
                    label: '設定',
                    fg: fg,
                    onTap: onSettings,
                  ),
                  _ChromeBtn(
                    icon: Icons.skip_next_outlined,
                    label: '下一章',
                    fg: hasNext ? fg : fg.withOpacity(0.3),
                    onTap: hasNext ? onNextChapter : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── 正文分發 ───────────────────────────

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    super.key,
    required this.chapter,
    required this.settings,
    required this.baseStyle,
    required this.pageTurnNotifier,
    required this.onPrev,
    required this.onNext,
    required this.onPageChanged,
    required this.bookTitle,
    required this.chapterTitle,
    this.initialPageIndex,
    this.initialScrollOffset,
  });

  final ChapterBody chapter;
  final ReaderSettings settings;
  final TextStyle baseStyle;
  final ValueNotifier<int> pageTurnNotifier;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final void Function(int page, int total) onPageChanged;
  final int? initialPageIndex;
  final double? initialScrollOffset;
  final String bookTitle;
  final String chapterTitle;

  @override
  Widget build(BuildContext context) {
    final padH = settings.pageMargin.value;
    switch (settings.pageMode) {
      case PageTurnMode.scroll:
        return _ScrollReader(
          chapter: chapter,
          baseStyle: baseStyle,
          padH: padH,
          initialScrollOffset: initialScrollOffset,
          bookTitle: bookTitle,
          chapterTitle: chapterTitle,
          onPrev: onPrev,
          onNext: onNext,
        );
      case PageTurnMode.slide:
        return _PageReader(
          chapter: chapter,
          baseStyle: baseStyle,
          padH: padH,
          initialPageIndex: initialPageIndex,
          bookTitle: bookTitle,
          chapterTitle: chapterTitle,
          pageTurnNotifier: pageTurnNotifier,
          onPrev: onPrev,
          onNext: onNext,
          curl: false,
          onPageChanged: onPageChanged,
        );
      case PageTurnMode.curl:
        return _PageReader(
          chapter: chapter,
          baseStyle: baseStyle,
          padH: padH,
          initialPageIndex: initialPageIndex,
          bookTitle: bookTitle,
          chapterTitle: chapterTitle,
          pageTurnNotifier: pageTurnNotifier,
          onPrev: onPrev,
          onNext: onNext,
          curl: true,
          onPageChanged: onPageChanged,
        );
    }
  }
}

// ─────────────────────────── 上下滑模式 ───────────────────────────

class _ScrollReader extends StatefulWidget {
  const _ScrollReader({
    required this.chapter,
    required this.baseStyle,
    required this.padH,
    required this.onPrev,
    required this.onNext,
    required this.bookTitle,
    required this.chapterTitle,
    this.initialScrollOffset,
  });

  final ChapterBody chapter;
  final TextStyle baseStyle;
  final double padH;
  final double? initialScrollOffset;
  final String bookTitle;
  final String chapterTitle;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;

  @override
  State<_ScrollReader> createState() => _ScrollReaderState();
}

class _ScrollReaderState extends State<_ScrollReader> {
  late final ScrollController _ctrl =
      ScrollController(initialScrollOffset: widget.initialScrollOffset ?? 0);
  double _overscroll = 0;
  bool _fired = false;
  static const _threshold = 80.0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _onNotif(ScrollNotification n) {
    if (n is OverscrollNotification) {
      _overscroll += n.overscroll;
      if (!_fired && _overscroll.abs() >= _threshold) {
        _fired = true;
        if (_overscroll < 0) {
          widget.onPrev();
        } else {
          widget.onNext();
        }
      }
    } else if (n is ScrollEndNotification || n is ScrollStartNotification) {
      _overscroll = 0;
      _fired = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final paragraphSpacing = widget.baseStyle.fontSize! * 0.85;
    final titleStyle = GoogleFonts.notoSerifTc(
      fontSize: widget.baseStyle.fontSize! + 4,
      fontWeight: FontWeight.w700,
      height: 1.4,
      color: widget.baseStyle.color,
    );

    final headerColor = widget.baseStyle.color?.withOpacity(0.38) ?? Colors.grey;

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onNotif,
          child: ListView(
            controller: _ctrl,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: EdgeInsets.fromLTRB(widget.padH, 56, widget.padH, 64),
            children: [
              if (widget.chapter.title.isNotEmpty) ...[
                Text(widget.chapter.title, style: titleStyle),
                SizedBox(height: paragraphSpacing * 1.6),
              ],
              for (final p in widget.chapter.paragraphs) ...[
                Text(
                  '\u3000\u3000${p.trim()}',
                  style: widget.baseStyle,
                  textAlign: TextAlign.justify,
                  strutStyle: StrutStyle(
                    fontSize: widget.baseStyle.fontSize,
                    height: widget.baseStyle.height,
                    forceStrutHeight: true,
                  ),
                ),
                SizedBox(height: paragraphSpacing),
              ],
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    '— 繼續上滑進入下一章 —',
                    style: GoogleFonts.notoSansTc(
                      fontSize: 12,
                      color: widget.baseStyle.color?.withOpacity(0.4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: paragraphSpacing * 2),
            ],
          ),
        ),
        // 頂部 chrome（章節 / 書名）
        Positioned(
          top: 16,
          left: widget.padH,
          right: widget.padH,
          child: SizedBox(
            height: _kPageHeaderH,
            child: _PageHeader(
              left: widget.chapterTitle,
              right: widget.bookTitle,
              color: headerColor,
            ),
          ),
        ),
        // 底部 chrome（時間 + 電量）
        Positioned(
          bottom: 16,
          left: widget.padH,
          right: widget.padH,
          child: SizedBox(
            height: _kStatusBarH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _TimeDisplay(color: headerColor),
                const SizedBox(width: 8),
                _BatteryDisplay(color: headerColor),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── 分頁模式（左右翻 / 仿真翻） ───────────────────────────

class _PageReader extends StatefulWidget {
  const _PageReader({
    required this.chapter,
    required this.baseStyle,
    required this.padH,
    required this.pageTurnNotifier,
    required this.onPrev,
    required this.onNext,
    required this.curl,
    required this.onPageChanged,
    required this.bookTitle,
    required this.chapterTitle,
    this.initialPageIndex,
  });

  final ChapterBody chapter;
  final TextStyle baseStyle;
  final double padH;
  final int? initialPageIndex;
  final String bookTitle;
  final String chapterTitle;
  final ValueNotifier<int> pageTurnNotifier;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final bool curl;
  final void Function(int page, int total) onPageChanged;

  @override
  State<_PageReader> createState() => _PageReaderState();
}

class _PageReaderState extends State<_PageReader> {
  PageController? _pc;
  ChapterLayout? _layout;
  bool _paginating = false;
  Size? _lastSize;

  // 防止哨兵頁連續觸發章節切換
  bool _switchInFlight = false;

  @override
  void initState() {
    super.initState();
    widget.pageTurnNotifier.addListener(_onExternalPageTurn);
  }

  @override
  void dispose() {
    widget.pageTurnNotifier.removeListener(_onExternalPageTurn);
    _pc?.dispose();
    _layout?.dispose();
    super.dispose();
  }

  void _onExternalPageTurn() {
    final delta = widget.pageTurnNotifier.value;
    if (delta == 0) return;
    widget.pageTurnNotifier.value = 0; // 消費
    final pc = _pc;
    if (pc == null || !pc.hasClients) return;
    final current = pc.page?.round() ?? 1;
    final pageCount = _layout?.pageCount ?? 0;
    final target = current + delta;
    if (target < 0 || target >= pageCount + 2) return;
    pc.animateToPage(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  void _paginate(Size size) {
    if (_paginating) return;
    if (size == _lastSize && _layout != null) return;
    _paginating = true;
    _lastSize = size;

    final fullText = _composeFull(widget.chapter);
    final pageW = size.width - widget.padH * 2;

    // 文本可用區高度（由 ChapterLayout 內部按實測行高換算 contentH，避免半字截斷）
    final availH = size.height - _kPagePadTop - _kStatusBarH;

    final strutStyle = StrutStyle(
      fontSize: widget.baseStyle.fontSize,
      height: widget.baseStyle.height,
      forceStrutHeight: true,
    );

    _layout?.dispose();
    final newLayout = ChapterLayout.layout(
      fullText: fullText,
      style: widget.baseStyle,
      strutStyle: strutStyle,
      pageWidth: pageW,
      availableHeight: availH,
    );

    // 保持當前頁位置（哨兵頁 offset = 1）；首次分頁優先使用 initialPageIndex
    int currentContent = 0;
    if (_pc != null && _pc!.hasClients) {
      currentContent = math.max(0, (_pc!.page?.round() ?? 1) - 1);
    } else if (widget.initialPageIndex != null) {
      currentContent = widget.initialPageIndex!;
    }
    currentContent = currentContent.clamp(0, math.max(0, newLayout.pageCount - 1));

    _pc?.dispose();
    _pc = PageController(initialPage: currentContent + 1);

    setState(() {
      _layout = newLayout;
      _paginating = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onPageChanged(currentContent, newLayout.pageCount);
    });
  }

  /// 把整章拼成一個字符串，交給 ChapterPaginator 做行級分頁。
  /// 段落之間插入一個空行（\n\n），末尾不加多餘換行，
  /// 確保最後一頁不帶尾部空行。
  String _composeFull(ChapterBody body) {
    final sb = StringBuffer();
    if (body.title.isNotEmpty) {
      sb.write(body.title);
      sb.write('\n\n');
    }
    final paras = body.paragraphs.where((p) => p.trim().isNotEmpty).toList();
    for (int i = 0; i < paras.length; i++) {
      sb.write('\u3000\u3000${paras[i].trim()}');
      if (i < paras.length - 1) sb.write('\n\n'); // 段落間空行，末段不加
    }
    return sb.toString();
  }

  void _onPageChanged(int index) {
    final contentPages = _layout?.pageCount ?? 0;
    if (index > 0 && index <= contentPages) {
      widget.onPageChanged(index - 1, contentPages);
    }

    if (_switchInFlight) return;
    if (index == 0) {
      _switchInFlight = true;
      widget.onPrev().whenComplete(() => _switchInFlight = false);
    } else if (index == contentPages + 1) {
      _switchInFlight = true;
      widget.onNext().whenComplete(() => _switchInFlight = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        if (_layout == null || size != _lastSize) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _paginate(size));
        }

        final layout = _layout;
        if (layout == null) {
          return Center(
            child: CircularProgressIndicator(
              color: widget.baseStyle.color?.withOpacity(0.4),
              strokeWidth: 2,
            ),
          );
        }

        final total = layout.pageCount + 2; // 含兩個哨兵頁

        return PageView.builder(
          controller: _pc,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: total,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            Widget page;
            if (index == 0) {
              page = _SentinelPage(
                label: '上一章',
                subLabel: '再次左滑切換',
                color: widget.baseStyle.color!,
              );
            } else if (index == total - 1) {
              page = _SentinelPage(
                label: '下一章',
                subLabel: '再次右滑切換',
                color: widget.baseStyle.color!,
              );
            } else {
              page = _PageContent(
                layout: layout,
                pageIndex: index - 1,
                baseStyle: widget.baseStyle,
                padH: widget.padH,
                bookTitle: widget.bookTitle,
                chapterTitle: widget.chapterTitle,
              );
            }
            if (!widget.curl) return page;
            // 仿真翻頁：3D 視差旋轉
            return AnimatedBuilder(
              animation: _pc!,
              builder: (context, child) {
                double v = 0;
                if (_pc!.position.haveDimensions) {
                  v = (_pc!.page ?? _pc!.initialPage.toDouble()) - index;
                }
                v = v.clamp(-1.0, 1.0);
                final m = Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(v * (math.pi / 2.4));
                return Transform(
                  alignment:
                      v < 0 ? Alignment.centerRight : Alignment.centerLeft,
                  transform: m,
                  child: child,
                );
              },
              child: page,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────── 頁面內容 ───────────────────────────
//
// 直接用 [CustomPaint] 在每頁上畫 **共用 TextPainter** 的對應 y 區段。
// 因為整章只排版一次、所有頁共用同一份畫布坐標，故每頁渲染高度
// 與 paginator 計算的 `contentH` **像素級一致**，從根本上沒有
// 「測量 vs 渲染」的差異。

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.layout,
    required this.pageIndex,
    required this.baseStyle,
    required this.padH,
    required this.bookTitle,
    required this.chapterTitle,
  });

  final ChapterLayout layout;
  final int pageIndex;
  final TextStyle baseStyle;
  final double padH;
  final String bookTitle;
  final String chapterTitle;

  @override
  Widget build(BuildContext context) {
    final subtleColor = baseStyle.color?.withOpacity(0.38) ?? Colors.grey;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 頂部狀態列：左 章節名，右 書名
          SizedBox(
            height: _kPageHeaderH,
            child: _PageHeader(
              left: chapterTitle,
              right: bookTitle,
              color: subtleColor,
            ),
          ),
          SizedBox(height: _kPageHeaderGap),
          // 整章排版的 y 區段 [pageIndex*contentH, (pageIndex+1)*contentH)
          ClipRect(
            child: SizedBox(
              width: layout.pageWidth,
              height: layout.contentH,
              child: CustomPaint(
                painter: _ChapterSlicePainter(layout: layout, pageIndex: pageIndex),
                size: Size(layout.pageWidth, layout.contentH),
              ),
            ),
          ),
          SizedBox(height: _kPageFooterGap),
          // 底部狀態列：左 頁碼，右 時間 + 電量
          SizedBox(
            height: _kStatusBarH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${pageIndex + 1} / ${layout.pageCount}',
                    style: GoogleFonts.notoSansTc(fontSize: 10, color: subtleColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _TimeDisplay(color: subtleColor),
                const SizedBox(width: 8),
                _BatteryDisplay(color: subtleColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 頁面頂部「章節名 · 書名」狀態列
class _PageHeader extends StatelessWidget {
  const _PageHeader({
    required this.left,
    required this.right,
    required this.color,
  });
  final String left;
  final String right;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final st = GoogleFonts.notoSansTc(fontSize: 10, color: color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            left,
            style: st,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            right,
            style: st,
            maxLines: 1,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ChapterSlicePainter extends CustomPainter {
  _ChapterSlicePainter({required this.layout, required this.pageIndex});
  final ChapterLayout layout;
  final int pageIndex;

  @override
  void paint(Canvas canvas, Size size) {
    layout.paintPage(canvas, pageIndex);
  }

  @override
  bool shouldRepaint(covariant _ChapterSlicePainter old) =>
      old.layout != layout || old.pageIndex != pageIndex;
}

/// 常駐電量顯示（每 60 秒刷新一次；圖示 + 百分比）
class _BatteryDisplay extends StatefulWidget {
  const _BatteryDisplay({required this.color});
  final Color color;

  @override
  State<_BatteryDisplay> createState() => _BatteryDisplayState();
}

class _BatteryDisplayState extends State<_BatteryDisplay> {
  final _battery = Battery();
  int? _level;
  StreamSubscription<BatteryState>? _stateSub;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
    _stateSub = _battery.onBatteryStateChanged.listen((_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final l = await _battery.batteryLevel;
      if (mounted) setState(() => _level = l);
    } catch (_) {/* 部分設備不支持 */}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lv = _level ?? 100;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 10,
          child: CustomPaint(painter: _BatteryPainter(level: lv, color: widget.color)),
        ),
        const SizedBox(width: 4),
        Text(
          '$lv%',
          style: GoogleFonts.notoSansTc(fontSize: 10, color: widget.color),
        ),
      ],
    );
  }
}

class _BatteryPainter extends CustomPainter {
  _BatteryPainter({required this.level, required this.color});
  final int level;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final body = Rect.fromLTWH(0, 0, size.width - 2, size.height);
    final r = RRect.fromRectAndRadius(body, const Radius.circular(1.5));
    canvas.drawRRect(r, paint);

    // 電池正極小帽
    final cap = Rect.fromLTWH(size.width - 2, size.height * 0.25, 2, size.height * 0.5);
    canvas.drawRect(cap, Paint()..color = color);

    // 內部填充
    final pct = (level.clamp(0, 100)) / 100.0;
    final inner = Rect.fromLTWH(1.5, 1.5, (body.width - 3) * pct, body.height - 3);
    canvas.drawRect(inner, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _BatteryPainter old) =>
      old.level != level || old.color != color;
}

/// 常駐時間顯示（每分鐘更新）
class _TimeDisplay extends StatefulWidget {
  const _TimeDisplay({required this.color});
  final Color color;

  @override
  State<_TimeDisplay> createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<_TimeDisplay> {
  late String _time;
  late final Stream<String> _stream;

  @override
  void initState() {
    super.initState();
    _time = _fmt(DateTime.now());
    // 每隔 30 秒更新一次（節省電量）
    _stream = Stream.periodic(const Duration(seconds: 30), (_) => _fmt(DateTime.now()));
  }

  String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String>(
      stream: _stream,
      initialData: _time,
      builder: (_, snap) => Text(
        snap.data ?? _time,
        style: GoogleFonts.notoSansTc(fontSize: 10, color: widget.color),
      ),
    );
  }
}

// ─────────────────────────── 哨兵頁 ───────────────────────────

class _SentinelPage extends StatelessWidget {
  const _SentinelPage({
    required this.label,
    required this.subLabel,
    required this.color,
  });
  final String label;
  final String subLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansTc(
              color: color.withOpacity(0.6),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subLabel,
            style: GoogleFonts.notoSansTc(
              color: color.withOpacity(0.35),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── 錯誤視圖 ───────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.fg, required this.onRetry});
  final String message;
  final Color fg;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: fg.withOpacity(0.5), size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSansTc(color: fg.withOpacity(0.75), fontSize: 14),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('重新加載'),
              style: OutlinedButton.styleFrom(foregroundColor: fg),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── 書架按鈕 ───────────────────────────

class _ShelfToggleButton extends StatelessWidget {
  const _ShelfToggleButton({required this.bookId, required this.fg});
  final int bookId;
  final Color fg;

  Future<void> _add(BuildContext context) async {
    final repo = context.read<IbooksRepository>();
    final shelf = context.read<ShelfController>();
    try {
      final book = await repo.bookDetail(bookId);
      if (book != null) {
        await shelf.addFromBook(book);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('已加入書架'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('加入失敗：$e')));
      }
    }
  }

  Future<void> _remove(BuildContext context) async {
    await context.read<ShelfController>().remove(bookId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('已從書架移除'), duration: Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelf = context.watch<ShelfController>();
    final inShelf = shelf.contains(bookId);
    return Tooltip(
      message: inShelf ? '已在書架（長按移除）' : '加入書架',
      child: InkResponse(
        radius: 22,
        onTap: () {
          if (inShelf) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('已在書架，長按可移除'),
                  duration: Duration(seconds: 1)),
            );
          } else {
            _add(context);
          }
        },
        onLongPress: inShelf ? () => _remove(context) : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            inShelf ? Icons.bookmark : Icons.bookmark_border,
            color: fg,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Chrome 按鈕 ───────────────────────────

class _ChromeBtn extends StatelessWidget {
  const _ChromeBtn({
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
    return InkResponse(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.notoSansTc(fontSize: 10.5, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}
