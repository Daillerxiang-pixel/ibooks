import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../src/data/ibooks_repository.dart';
import '../../theme/ibooks_colors.dart';
import '../../widgets/book_covers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/section_title_row.dart';

/// 分類頁：分類網格與「分類熱門」全部來自後端 `/api/books`，
/// 沒有分類接口時，從書籍 [BookRow.category] 動態派生。
class CategoryTab extends StatefulWidget {
  const CategoryTab({super.key});

  @override
  State<CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends State<CategoryTab> {
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

  Map<String, int> get _categoryCounts {
    final m = <String, int>{};
    for (final b in (_books ?? [])) {
      final c = (b.category ?? '').trim();
      if (c.isEmpty) continue;
      m[c] = (m[c] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _books == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_err != null && (_books == null || _books!.isEmpty)) {
      return ErrorState(message: '加載分類失敗：\n$_err', onRetry: _load);
    }
    final cats = _categoryCounts;
    final hot = (_books ?? []).take(6).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
        children: [
          const SectionTitleRow(title: '全部分類', marginTop: 0),
          if (cats.isEmpty)
            const Text(
              '暫無分類數據',
              style: TextStyle(color: IbColors.inkMuted),
            )
          else
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.95,
              children: [
                  for (final entry in cats.entries)
                    InkWell(
                      onTap: () => context.push(
                        '/catlist?cat=${Uri.encodeQueryComponent(entry.key)}',
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: IbColors.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Color(0x141A1A1A), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              entry.key,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoSansTc(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.value} 本',
                              style: GoogleFonts.notoSansTc(
                                fontSize: 11,
                                color: IbColors.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          const SectionTitleRow(title: '分類熱門', marginTop: 16),
          if (hot.isEmpty)
            const Text(
              '暫無書籍數據',
              style: TextStyle(color: IbColors.inkMuted),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              childAspectRatio: 0.62,
              children: [
                for (final b in hot)
                  InkWell(
                    onTap: () => context.push('/detail/${b.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: NetworkBookCover(
                            coverUrl: b.coverUrl,
                            borderRadius: 10,
                            aspectRatio: 3 / 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansTc(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if ((b.category ?? '').isNotEmpty)
                          Text(
                            b.category!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.notoSansTc(
                              fontSize: 9.9,
                              color: IbColors.inkMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
