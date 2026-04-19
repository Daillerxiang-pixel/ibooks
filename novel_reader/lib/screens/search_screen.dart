import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../src/data/ibooks_repository.dart';
import '../theme/ibooks_colors.dart';
import '../widgets/book_covers.dart';
import '../widgets/error_state.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

/// 搜尋頁：客戶端對 `/api/books` 列表進行 title/author/category 模糊匹配。
/// （後端尚未提供 `/api/books/search` 接口時的過渡方案，無寫死數據。）
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  List<BookRow>? _all;
  String? _err;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
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
        _all = list;
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

  List<BookRow> _matches() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return (_all ?? []).where((b) {
      bool m(String? s) => s != null && s.toLowerCase().contains(q);
      return m(b.title) || m(b.author) || m(b.category);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '搜尋',
      subtitle: '書名 · 作者 · 分類',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: IbColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: IbColors.ink.withOpacity(0.45)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '輸入書名、作者或分類…',
                      hintStyle: GoogleFonts.notoSansTc(fontSize: 13.5, color: IbColors.inkMuted),
                      border: InputBorder.none,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (_query.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loading && _all == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_err != null && (_all == null || _all!.isEmpty))
            ErrorState(message: '加載書庫失敗：\n$_err', onRetry: _load)
          else
            _buildResults(),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Text(
          '輸入關鍵字開始搜尋（書名 / 作者 / 分類）',
          textAlign: TextAlign.center,
          style: GoogleFonts.notoSansTc(color: IbColors.inkMuted, fontSize: 12.5),
        ),
      );
    }
    final list = _matches();
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Text(
            '無相關書籍',
            style: TextStyle(color: IbColors.inkMuted),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final b in list)
          InkWell(
            onTap: () => context.push('/detail/${b.id}'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 44,
                    height: 58,
                    child: NetworkBookCover(
                      coverUrl: b.coverUrl,
                      borderRadius: 6,
                      aspectRatio: 44 / 58,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSansTc(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            if ((b.author ?? '').isNotEmpty) b.author!,
                            if ((b.category ?? '').isNotEmpty) b.category!,
                          ].join(' · '),
                          style: GoogleFonts.notoSansTc(fontSize: 11, color: IbColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
