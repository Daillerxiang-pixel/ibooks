import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/ibooks_colors.dart';
import '../widgets/ibooks_subpage_scaffold.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    return IbSubpageScaffold(
      title: '優惠券',
      subtitle: '餘額／面額 · 狀態',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(4, (i) {
                final labels = ['全部', '正常', '使用完', '已過期'];
                final on = _filter == i;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(labels[i], style: GoogleFonts.notoSansTc(fontSize: 11.5)),
                    selected: on,
                    onSelected: (_) => setState(() => _filter = i),
                    selectedColor: IbColors.accentSoft,
                    labelStyle: TextStyle(color: on ? IbColors.accent : IbColors.inkMuted, fontWeight: on ? FontWeight.w600 : FontWeight.w400),
                    side: BorderSide(color: on ? IbColors.accent.withValues(alpha: 0.3) : IbColors.line),
                    backgroundColor: IbColors.bgCard,
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 12),
          _CouponRow('32/50', '春季儲值滿額禮', '至 2026-08-31', '✓', const Color(0xFF1B5E20), _filter, 0),
          _CouponRow('100/200', '新用戶註冊贈送', '至 2026-12-31', '✓', const Color(0xFF1B5E20), _filter, 0),
          _CouponRow('0/20', '邀請好友達標禮', '曾有效至 2026-03-15', '○', IbColors.inkMuted, _filter, 1),
          _CouponRow('15/15', '端午限時活動', '已結束 2026-04-10', '×', IbColors.accent, _filter, 2),
          const SizedBox(height: 8),
          Text('圖示：✓ 正常 · ○ 使用完 · × 已過期（原型）。', textAlign: TextAlign.center, style: GoogleFonts.notoSansTc(fontSize: 10.5, color: IbColors.inkMuted)),
        ],
      ),
    );
  }
}

class _CouponRow extends StatelessWidget {
  const _CouponRow(this.ratio, this.src, this.exp, this.ico, this.icoColor, this.filter, this.bucket);

  final String ratio;
  final String src;
  final String exp;
  final String ico;
  final Color icoColor;
  final int filter;
  final int bucket;

  bool get _visible {
    if (filter == 0) return true;
    if (filter == 1) return bucket == 0;
    if (filter == 2) return bucket == 1;
    if (filter == 3) return bucket == 2;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: IbColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IbColors.line),
        boxShadow: const [BoxShadow(color: Color(0x141A1A1A), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(src, style: GoogleFonts.notoSansTc(fontSize: 13.1, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(exp, style: GoogleFonts.notoSansTc(fontSize: 10.9, color: IbColors.inkMuted)),
              ],
            ),
          ),
          Text(ratio, style: GoogleFonts.notoSansTc(fontSize: 15.7, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          const SizedBox(width: 10),
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: icoColor.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Text(ico, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: icoColor)),
          ),
        ],
      ),
    );
  }
}
