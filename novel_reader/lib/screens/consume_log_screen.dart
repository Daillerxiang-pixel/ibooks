import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class ConsumeLogScreen extends StatelessWidget {
  const ConsumeLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '消費記錄',
      subtitle: '書幣變動明細',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('書幣變動', style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _Row('解鎖章節《霓虹深處的約定》第 3 章', '2026-04-14 21:06 · 訂單 #C882910', '−12', true),
          _Row('解鎖章節《霓虹深處的約定》第 4 章', '2026-04-14 21:18 · 訂單 #C882911', '−12', true),
          _Row('儲值到帳（NT\$ 120 檔）', '2026-04-10 10:02 · 訂單 #R441102', '+1,280', false),
          const SizedBox(height: 10),
          Text('原型列表為示意；正式版分頁載入。', textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.title, this.sub, this.amt, this.minus);

  final String title;
  final String sub;
  final String amt;
  final bool minus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.notoSansTc(fontSize: 13.1, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(sub, style: GoogleFonts.notoSansTc(fontSize: 10.9, color: IbColors.inkMuted, height: 1.35)),
              ],
            ),
          ),
          Text(amt, style: GoogleFonts.notoSansTc(fontSize: 14.1, fontWeight: FontWeight.w700, color: minus ? IbColors.accent : const Color(0xFF2D6A4F))),
        ],
      ),
    );
  }
}
