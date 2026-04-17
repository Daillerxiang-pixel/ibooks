import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/chapter_list_args.dart';
import '../theme/ibooks_colors.dart';

class ReaderScreen extends StatelessWidget {
  const ReaderScreen({super.key});

  void _openToc(BuildContext context) {
    final router = GoRouter.of(context);
    router.pop();
    router.push('/chapterlist', extra: const ChapterListArgs(reopenReader: true));
  }

  @override
  Widget build(BuildContext context) {
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
                      '第 1 章 起風了',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: DefaultTextStyle(
                  style: GoogleFonts.notoSansTc(
                    fontSize: 17,
                    height: 1.95,
                    color: IbColors.readerFg,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('這是一段示範正文。下方「閱讀設定」可調字體、行距、背景與亮度。'),
                      SizedBox(height: 20),
                      Text('目標讀者為香港、澳門、台灣與東南亞等使用繁體中文的海外用戶。'),
                      SizedBox(height: 20),
                      Text('（實際產品將載入章節正文，並依權限顯示解鎖／付費入口。）'),
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
                  TextButton(onPressed: () {}, child: Text('上一章', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 12.5))),
                  TextButton(onPressed: () {}, child: Text('閱讀設定', style: GoogleFonts.notoSansTc(color: const Color(0xFFF0D78C), fontSize: 12.5, fontWeight: FontWeight.w600))),
                  TextButton(onPressed: () {}, child: Text('日／夜', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 12.5))),
                  TextButton(onPressed: () {}, child: Text('下一章', style: GoogleFonts.notoSansTc(color: IbColors.readerFg, fontSize: 12.5))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
