import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class RechargeOrdersScreen extends StatelessWidget {
  const RechargeOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '充值訂單',
      subtitle: '我的儲值訂單',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('充值訂單', style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          _Ord('NT\$ 120 · 得 1,280 書幣', '單號 R441102 · 2026-04-10 10:02', '已支付', '已發放', false),
          _Ord('NT\$ 60 · 得 600 書幣', '單號 R439801 · 2026-03-02 19:41', '已支付', '已發放', false),
          _Ord('NT\$ 300 · 得 3,300 書幣', '單號 R438200 · 待支付', '待付', '將過期', true),
          const SizedBox(height: 8),
          Text('含待支付／已發放等狀態示意。', textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}

class _Ord extends StatelessWidget {
  const _Ord(this.line1, this.line2, this.s1, this.s2, this.warn);

  final String line1;
  final String line2;
  final String s1;
  final String s2;
  final bool warn;

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
                Text(line1, style: GoogleFonts.notoSansTc(fontSize: 13.1, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(line2, style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(s1, style: GoogleFonts.notoSansTc(fontSize: 13.1, fontWeight: FontWeight.w600, color: warn ? IbColors.accent : const Color(0xFF2D6A4F))),
              const SizedBox(height: 4),
              Text(s2, style: GoogleFonts.notoSansTc(fontSize: 9.7, color: warn ? IbColors.accent : const Color(0xFF2D6A4F))),
            ],
          ),
        ],
      ),
    );
  }
}
