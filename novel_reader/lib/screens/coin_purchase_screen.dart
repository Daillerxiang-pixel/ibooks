import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class CoinPurchaseScreen extends StatelessWidget {
  const CoinPurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '書幣購買',
      subtitle: '儲值檔位 · 支付',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF3D2A28), Color(0xFF6B4535)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text('目前餘額（書幣）', style: GoogleFonts.notoSansTc(fontSize: 12.5, color: Colors.white70)),
                const SizedBox(height: 4),
                Text('1,280', style: GoogleFonts.notoSansTc(fontSize: 26.4, fontWeight: FontWeight.w700, color: const Color(0xFFFFE566))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('選擇儲值檔位', style: GoogleFonts.notoSansTc(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              _Pkg('60', '600', false),
              _Pkg('120', '1,280', true, tag: '多送一點'),
              _Pkg('300', '3,300', false),
              _Pkg('500', '5,800', false, tag: '划算'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '原型：點檔位示意下單；正式版接金流與到帳。',
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _Pkg extends StatelessWidget {
  const _Pkg(this.price, this.get, this.hot, {this.tag});

  final String price;
  final String get;
  final bool hot;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: hot ? IbColors.accentSoft : IbColors.bgCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: hot ? IbColors.accent.withOpacity(0.5) : IbColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('NT\$ $price', style: GoogleFonts.notoSansTc(fontSize: 16.8, fontWeight: FontWeight.w700, color: IbColors.accent)),
              const SizedBox(height: 6),
              Text('得 $get 書幣', style: GoogleFonts.notoSansTc(fontSize: 11.5, color: IbColors.inkMuted)),
              if (tag != null) ...[
                const SizedBox(height: 4),
                Text(tag!, style: GoogleFonts.notoSansTc(fontSize: 9.3, color: IbColors.accent, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
