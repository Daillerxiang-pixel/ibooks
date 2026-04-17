import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';
import '../widgets/section_title_row.dart';

class ChapterListScreen extends StatelessWidget {
  const ChapterListScreen({super.key, this.reopenReaderOnPop = false});

  final bool reopenReaderOnPop;

  void _handleBack(BuildContext context) {
    context.pop();
    if (reopenReaderOnPop) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.push('/reader');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) _handleBack(context);
      },
      child: IbSubpageScaffold(
        title: '目錄',
        subtitle: '章節列表 · 解鎖狀態',
        onBack: () => _handleBack(context),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '霓虹深處的約定',
              style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
            ),
            Text(
              '連載 · 付費章節以站內標示為準',
              style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted),
            ),
            const SizedBox(height: 12),
            _Chap('第 1 章 起風了', false, () => context.push('/reader')),
            _Chap('第 2 章 轉角咖啡館', false, () => context.push('/reader')),
            _Chap('第 3 章 霓虹背面', true, () => context.push('/reader')),
            _Chap('第 4 章 未寄出的信', true, () => context.push('/reader')),
            _Chap('第 5 章 港島夜色', true, () => context.push('/reader')),
            _Chap('第 6 章 舊事如風', true, () => context.push('/reader')),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('… 以下略（原型）', textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
            ),
            const HintLine('與詳情頁、閱讀器「目錄」進入同一頁；點章節可回到閱讀（原型）。'),
          ],
        ),
      ),
    );
  }
}

class _Chap extends StatelessWidget {
  const _Chap(this.title, this.paid, this.onTap);

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
