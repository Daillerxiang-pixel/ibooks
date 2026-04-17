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
import '../src/data/shelf_controller.dart';
import '../src/domain/chapter_body.dart';
import '../src/domain/chapter_meta.dart';
import '../src/reader/paginator.dart';
import '../theme/app_layout.dart';
import '../widgets/reader_settings_sheet.dart';

/// 沉浸式閱讀器：
/// - 預設 **隱藏所有控件**；點擊正文中央 → 切換顯示
/// - 頂部：返回 / 標題 / 加入書架
/// - 底部：目錄 / 日夜 / 閱讀設定
/// - 翻頁三種：上下滑、左右翻、仿真翻
/// - 上下滑模式：到頂/底再次拉一段 → 自動切上/下章
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
  bool _switching = false;
  List<ChapterListItem>? _toc;
  bool _chromeVisible = false;
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
    if (_switching) return;
    _switching = true;
    await _ensureToc();
    final toc = _toc;
    if (toc == null || toc.isEmpty) {
      _switching = false;
      return;
    }
    final i = toc.indexWhere((c) => c.id == widget.chapterId);
    if (i < 0) {
      _switching = false;
      return;
    }
    final j = i + delta;
    if (j < 0) {
      _toast('已是第一章');
      _switching = false;
      return;
    }
    if (j >= toc.length) {
      _toast('已是最後一章');
      _switching = false;
      return;
    }
    final next = toc[j];
    if (!mounted) {
      _switching = false;
      return;
    }
    HapticFeedback.lightImpact();
    context.go('/reader/${next.id}?bookId=${widget.bookId}');
    _switching = false;
  }

  void _toast(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s), duration: const Duration(seconds: 1)),
    );
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

  void _toggleChromeOnTap(TapUpDetails d, double width, double height) {
    final dx = d.localPosition.dx;
    final dy = d.localPosition.dy;
    final inMidX = dx > width * 0.2 && dx < width * 0.8;
    final inMidY = dy > height * 0.25 && dy < height * 0.75;
    if (inMidX && inMidY) {
      HapticFeedback.selectionClick();
      setState(() => _chromeVisible = !_chromeVisible);
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
                        onTapUp: (d) => _toggleChromeOnTap(d, c.maxWidth, c.maxHeight),
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
                                : _ReaderBody(
                                    key: ValueKey('${widget.chapterId}-${settings.pageMode.name}-${settings.fontSize.toInt()}-${settings.lineSpacing.name}-${settings.family.name}'),
                                    chapter: _body!,
                                    settings: settings,
                                    baseStyle: baseTextStyle,
                                    onPrev: () => _goNeighbor(-1),
                                    onNext: () => _goNeighbor(1),
                                  ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 頂部：返回 / 標題 / 加入書架
          AnimatedSlide(
            offset: Offset(0, _chromeVisible ? 0 : -1),
            duration: const Duration(milliseconds: 220),
            child: AnimatedOpacity(
              opacity: _chromeVisible ? 1 : 0,
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
                            style: GoogleFonts.notoSansTc(color: fg, fontSize: 14.5, fontWeight: FontWeight.w600),
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
          // 底部：目錄 / 日夜 / 閱讀設定
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
                            icon: Icons.menu_book_outlined,
                            label: '目錄',
                            fg: fg,
                            onTap: () => _openToc(context),
                          ),
                          _BottomBtn(
                            icon: settings.theme == ReaderTheme.dark
                                ? Icons.wb_sunny_outlined
                                : Icons.nights_stay_outlined,
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

// ---------------- 正文渲染（依翻頁方式分發） ----------------

class _ReaderBody extends StatelessWidget {
  const _ReaderBody({
    super.key,
    required this.chapter,
    required this.settings,
    required this.baseStyle,
    required this.onPrev,
    required this.onNext,
  });

  final ChapterBody chapter;
  final ReaderSettings settings;
  final TextStyle baseStyle;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    switch (settings.pageMode) {
      case PageTurnMode.scroll:
        return _ScrollReader(
          chapter: chapter,
          baseStyle: baseStyle,
          onPrev: onPrev,
          onNext: onNext,
        );
      case PageTurnMode.slide:
        return _PageReader(
          chapter: chapter,
          baseStyle: baseStyle,
          onPrev: onPrev,
          onNext: onNext,
          curl: false,
        );
      case PageTurnMode.curl:
        return _PageReader(
          chapter: chapter,
          baseStyle: baseStyle,
          onPrev: onPrev,
          onNext: onNext,
          curl: true,
        );
    }
  }
}

// ---------------- 模式 1：上下滑 + 邊緣再拉換章 ----------------

class _ScrollReader extends StatefulWidget {
  const _ScrollReader({
    required this.chapter,
    required this.baseStyle,
    required this.onPrev,
    required this.onNext,
  });

  final ChapterBody chapter;
  final TextStyle baseStyle;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;

  @override
  State<_ScrollReader> createState() => _ScrollReaderState();
}

class _ScrollReaderState extends State<_ScrollReader> {
  final _ctrl = ScrollController();
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
    } else if (n is ScrollEndNotification) {
      _overscroll = 0;
      _fired = false;
    } else if (n is ScrollStartNotification) {
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

    return NotificationListener<ScrollNotification>(
      onNotification: _onNotif,
      child: ListView(
        controller: _ctrl,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(20, 56, 20, 64),
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
                '— 上滑進入下一章 —',
                style: GoogleFonts.notoSansTc(
                  fontSize: 12,
                  color: widget.baseStyle.color?.withOpacity(0.45),
                ),
              ),
            ),
          ),
          SizedBox(height: paragraphSpacing * 2),
        ],
      ),
    );
  }
}

// ---------------- 模式 2/3：分頁 PageView + 翻頁過場（curl） ----------------
//
// 在「正文頁」前後插入 **哨兵頁**（上一章 / 下一章）；用戶滑到哨兵 → 切章。
// 這比依賴 OverscrollNotification 更穩定，左右翻 / 仿真翻一致。

const double _kPagePadH = 18;
const double _kPagePadV = 36;

class _PageReader extends StatefulWidget {
  const _PageReader({
    required this.chapter,
    required this.baseStyle,
    required this.onPrev,
    required this.onNext,
    required this.curl,
  });

  final ChapterBody chapter;
  final TextStyle baseStyle;
  final Future<void> Function() onPrev;
  final Future<void> Function() onNext;
  final bool curl;

  @override
  State<_PageReader> createState() => _PageReaderState();
}

class _PageReaderState extends State<_PageReader> {
  late final PageController _pc = PageController(initialPage: 1);
  bool _switchInFlight = false;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, int contentPages) {
    if (_switchInFlight) return;
    // index 0 = 上一章哨兵；index = contentPages + 1 = 下一章哨兵
    if (index == 0) {
      _switchInFlight = true;
      widget.onPrev();
    } else if (index == contentPages + 1) {
      _switchInFlight = true;
      widget.onNext();
    }
  }

  String _composeFull(ChapterBody body) {
    final sb = StringBuffer();
    if (body.title.isNotEmpty) {
      sb.writeln(body.title);
      sb.writeln();
    }
    for (final p in body.paragraphs) {
      sb.write('\u3000\u3000${p.trim()}');
      sb.writeln();
      sb.writeln();
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final fullText = _composeFull(widget.chapter);

    return LayoutBuilder(
      builder: (context, c) {
        // 真實可繪文本區（嚴格扣除四周 padding）
        final pageW = c.maxWidth - _kPagePadH * 2;
        final pageH = c.maxHeight - _kPagePadV * 2;
        final paginator = ChapterPaginator(
          fullText: fullText,
          style: widget.baseStyle,
          size: Size(pageW, pageH),
          strutStyle: StrutStyle(
            fontSize: widget.baseStyle.fontSize,
            height: widget.baseStyle.height,
            forceStrutHeight: true,
          ),
        );
        final contentPages = paginator.paginate();
        // 哨兵頁包裹
        final total = contentPages.length + 2;

        return PageView.builder(
          controller: _pc,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          itemCount: total,
          onPageChanged: (i) => _onPageChanged(i, contentPages.length),
          itemBuilder: (context, index) {
            Widget page;
            if (index == 0) {
              page = _SentinelPage(
                text: '← 滑到首頁\n再次左滑：上一章',
                color: widget.baseStyle.color!,
              );
            } else if (index == total - 1) {
              page = _SentinelPage(
                text: '滑到末頁 →\n再次右滑：下一章',
                color: widget.baseStyle.color!,
              );
            } else {
              page = _PageContent(
                text: contentPages[index - 1],
                index: index,
                total: contentPages.length,
                baseStyle: widget.baseStyle,
              );
            }
            if (!widget.curl) return page;
            return AnimatedBuilder(
              animation: _pc,
              builder: (context, child) {
                double v = 0;
                if (_pc.position.haveDimensions) {
                  v = (_pc.page ?? _pc.initialPage.toDouble()) - index;
                }
                v = v.clamp(-1.0, 1.0);
                final m = Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..rotateY(v * (math.pi / 2.4));
                return Transform(
                  alignment: v < 0 ? Alignment.centerRight : Alignment.centerLeft,
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

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.text,
    required this.index,
    required this.total,
    required this.baseStyle,
  });

  final String text;
  final int index;
  final int total;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    // 為保證文本鋪滿可用區，使用 OverflowBox 將 Text 對齊到頂部，
    // 同時把翻頁進度寫到右下角的小角標，不再佔用單獨一行。
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(_kPagePadH, _kPagePadV, _kPagePadH, _kPagePadV),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                text,
                style: baseStyle,
                textAlign: TextAlign.justify,
                strutStyle: StrutStyle(
                  fontSize: baseStyle.fontSize,
                  height: baseStyle.height,
                  forceStrutHeight: true,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: _kPagePadH,
          bottom: 8,
          child: Text(
            '$index / ${total + 1}',
            style: GoogleFonts.notoSansTc(
              fontSize: 10.5,
              color: baseStyle.color?.withOpacity(0.45),
            ),
          ),
        ),
      ],
    );
  }
}

class _SentinelPage extends StatelessWidget {
  const _SentinelPage({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansTc(
            color: color.withOpacity(0.55),
            fontSize: 14,
            height: 1.8,
          ),
        ),
      ),
    );
  }
}

// ---------------- 共用 Widgets ----------------

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
            const SnackBar(content: Text('已加入書架'), duration: Duration(seconds: 1)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加入失敗：$e')),
        );
      }
    }
  }

  Future<void> _remove(BuildContext context) async {
    await context.read<ShelfController>().remove(bookId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已從書架移除'), duration: Duration(seconds: 1)),
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
              const SnackBar(content: Text('已在書架，長按可移除'), duration: Duration(seconds: 1)),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
