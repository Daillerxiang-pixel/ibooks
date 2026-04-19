import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../src/data/ibooks_repository.dart';
import '../../src/data/session_controller.dart';
import '../../src/data/shelf_controller.dart';
import '../../theme/ibooks_colors.dart';
import '../../widgets/book_covers.dart';
import '../../widgets/section_title_row.dart';

class ShelfTab extends StatefulWidget {
  const ShelfTab({super.key});

  @override
  State<ShelfTab> createState() => _ShelfTabState();
}

class _ShelfTabState extends State<ShelfTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShelfController>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shelf = context.watch<ShelfController>();
    final session = context.watch<SessionController>();
    final items = shelf.items;

    return RefreshIndicator(
      onRefresh: () => shelf.refresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          if (!session.isLoggedIn)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: IbColors.bgCard,
                borderRadius: BorderRadius.circular(10),
                child: ListTile(
                  dense: true,
                  title: Text(
                    '未登入：書架僅本機可見。登入後將自動合併到雲端。',
                    style: GoogleFonts.notoSansTc(fontSize: 12.5),
                  ),
                  trailing: TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('登入'),
                  ),
                ),
              ),
            ),
          if (shelf.lastError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                shelf.lastError!,
                style: GoogleFonts.notoSansTc(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          SectionTitleRow(
            title: '書架收藏',
            marginTop: 0,
            trailing: Text(
              '${items.length} 本',
              style: GoogleFonts.notoSansTc(fontSize: 12, color: IbColors.accent),
            ),
          ),
          if (shelf.isLoading && items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('書架空空如也，去書城逛逛吧',
                    style: GoogleFonts.notoSansTc(fontSize: 13, color: IbColors.inkMuted)),
              ),
            )
          else
            _ShelfGrid(items: items),
        ],
      ),
    );
  }
}

class _ShelfGrid extends StatelessWidget {
  const _ShelfGrid({required this.items});
  final List<BookRow> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const cols = 3;
        const gap = 10.0;
        final cellW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: 14,
          children: items
              .map((b) => SizedBox(
                    width: cellW,
                    child: _ShelfBook(book: b),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ShelfBook extends StatelessWidget {
  const _ShelfBook({required this.book});
  final BookRow book;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/detail/${book.id}'),
      onLongPress: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('從書架移除'),
            content: Text('確定要把《${book.title}》從書架移除嗎？'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('移除')),
            ],
          ),
        );
        if (ok == true && context.mounted) {
          await context.read<ShelfController>().remove(book.id);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NetworkBookCover(coverUrl: book.coverUrl, borderRadius: 10, aspectRatio: 3 / 4),
          const SizedBox(height: 6),
          Text(
            book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSansTc(fontSize: 11.8, fontWeight: FontWeight.w500),
          ),
          if ((book.author ?? '').isNotEmpty)
            Text(
              book.author!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.notoSansTc(fontSize: 10, color: IbColors.inkMuted),
            ),
        ],
      ),
    );
  }
}
