import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class VipPurchaseScreen extends StatelessWidget {
  const VipPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '會員購買',
      subtitle: '包月套餐 · 規則與支付',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4A3540), Color(0xFF6B4A5C)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('5 倍', style: GoogleFonts.notoSansTc(fontSize: 36, fontWeight: FontWeight.w900, color: const Color(0xFFFFE566))),
                const SizedBox(height: 8),
                Text('包月優惠套餐', style: GoogleFonts.notoSansTc(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 6),
                Text('同價購幣 · 30 天累計領取量更高', style: GoogleFonts.notoSansTc(fontSize: 12.5, color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: IbColors.bgCard, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '用戶購買包月套餐後，每日可領取固定數量書幣；自購買日起連續 30 日內，累計領取書幣總量＝以相同價格單次購買書幣可獲得書幣總額的 5 倍。',
                  style: GoogleFonts.notoSansTc(fontSize: 13, height: 1.55),
                ),
                const SizedBox(height: 10),
                Text('• 公式：30 天每日領取之和 ＝ 5 ×（同價單次購幣可得總額）。', style: GoogleFonts.notoSansTc(fontSize: 12.5, height: 1.45, color: IbColors.inkMuted)),
                Text('• 單本解鎖、儲值購幣等規則可與包月並存，以站內說明為準。', style: GoogleFonts.notoSansTc(fontSize: 12.5, height: 1.45, color: IbColors.inkMuted)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IbColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: IbColors.accent.withValues(alpha: 0.35), style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Text('包月套餐（示意價）', style: GoogleFonts.notoSansTc(fontSize: 13.6, color: IbColors.inkMuted)),
                const SizedBox(height: 6),
                Text('NT\$ 99 / 30 天', style: GoogleFonts.notoSansTc(fontSize: 21.6, fontWeight: FontWeight.w700, color: IbColors.accent)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF5A3558),
            ),
            onPressed: () {},
            child: Text('立即購買', style: GoogleFonts.notoSansTc(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          Text(
            '原型按鈕不連支付；正式版接訂單與簽到領幣流程。',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted, height: 1.45),
          ),
        ],
      ),
    );
  }
}
